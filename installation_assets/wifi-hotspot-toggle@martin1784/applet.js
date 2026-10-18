const Applet = imports.ui.applet;
const Settings = imports.ui.settings;
const Main = imports.ui.main;
const Gio = imports.gi.Gio;
const GLib = imports.gi.GLib;
const NM = imports.gi.NM;
const Gettext = imports.gettext;

const UUID = "wifi-hotspot-toggle@martin1784";

// Translations live in ~/.local/share/locale; without a matching translation
// the English original text is shown.
Gettext.bindtextdomain(UUID, GLib.get_home_dir() + "/.local/share/locale");

function _(str) {
    const translated = Gettext.dgettext(UUID, str);
    return translated !== str ? translated : Gettext.gettext(str);
}

const STATE_OFF = 0;
const STATE_BUSY = 1;
const STATE_ON = 2;

class HotspotApplet extends Applet.IconApplet {
    constructor(metadata, orientation, panelHeight, instanceId) {
        super(orientation, panelHeight, instanceId);

        this._path = metadata.path;
        this._client = null;
        this._clientSignals = [];
        this._acSignals = [];
        this._running = false;

        this.settings = new Settings.AppletSettings(this, metadata.uuid, instanceId);
        this.settings.bind("connection-name", "connectionName", () => this._update());
        this.settings.bind("ssid", "ssid");
        this.settings.bind("password", "password");

        this._applet_context_menu.addAction(_("Show hotspot password"), () => this._showPassword());
        this._applet_context_menu.addAction(_("Edit network connections"), () => {
            GLib.spawn_command_line_async("nm-connection-editor");
        });

        this._setIcon(STATE_OFF, _("Querying NetworkManager…"));

        NM.Client.new_async(null, (obj, res) => {
            try {
                this._client = NM.Client.new_finish(res);
            } catch (e) {
                global.logError("wifi-hotspot-toggle: NetworkManager nicht erreichbar: " + e.message);
                this._setIcon(STATE_OFF, _("NetworkManager not reachable"));
                return;
            }
            for (let sig of ["notify::active-connections", "connection-added", "connection-removed"])
                this._clientSignals.push(this._client.connect(sig, () => this._update()));
            this._update();
        });
    }

    _setIcon(state, tooltip) {
        const name = ["hotspot-off", "hotspot-busy", "hotspot-on"][state];
        this.set_applet_icon_path(this._path + "/icons/" + name + ".svg");
        this.set_applet_tooltip(tooltip);
    }

    _findConnection() {
        if (!this._client)
            return null;
        return this._client.get_connections().find(c => c.get_id() === this.connectionName) || null;
    }

    _findActive() {
        if (!this._client)
            return null;
        return this._client.get_active_connections().find(ac => ac.get_id() === this.connectionName) || null;
    }

    _getState() {
        const ac = this._findActive();
        if (!ac)
            return STATE_OFF;
        const s = ac.get_state();
        if (s === NM.ActiveConnectionState.ACTIVATED)
            return STATE_ON;
        if (s === NM.ActiveConnectionState.ACTIVATING || s === NM.ActiveConnectionState.DEACTIVATING)
            return STATE_BUSY;
        return STATE_OFF;
    }

    _getSsid() {
        const con = this._findConnection();
        const wifi = con ? con.get_setting_wireless() : null;
        const bytes = wifi ? wifi.get_ssid() : null;
        return bytes ? NM.utils_ssid_to_utf8(bytes.get_data()) : null;
    }

    _update() {
        // Watch state changes of the active connections (activating → active)
        for (let [ac, id] of this._acSignals)
            ac.disconnect(id);
        this._acSignals = [];
        if (this._client) {
            for (let ac of this._client.get_active_connections())
                this._acSignals.push([ac, ac.connect("notify::state", () => this._update())]);
        }

        const state = this._running ? STATE_BUSY : this._getState();
        const ssid = this._getSsid();
        const ssidText = ssid ? " (" + _("SSID: %s").format(ssid) + ")" : "";
        let tip;
        if (state === STATE_ON)
            tip = _("Hotspot on") + ssidText + "\n" + _("Click to switch off");
        else if (state === STATE_BUSY)
            tip = _("Switching hotspot…");
        else
            tip = _("Hotspot off") + ssidText + "\n" + _("Click to switch on");
        this._setIcon(state, tip);
    }

    on_applet_clicked(event) {
        if (this._running || !this._client)
            return;

        const name = this.connectionName;
        let argv;
        if (this._getState() !== STATE_OFF) {
            argv = ["nmcli", "connection", "down", "id", name];
        } else if (this._findConnection()) {
            argv = ["nmcli", "connection", "up", "id", name];
        } else {
            // Connection does not exist yet: let NetworkManager create it
            argv = ["nmcli", "device", "wifi", "hotspot", "con-name", name];
            if (this.ssid)
                argv.push("ssid", this.ssid);
            if (this.password)
                argv.push("password", this.password);
        }

        this._running = true;
        this._update();
        this._run(argv, (ok, stdout, stderr) => {
            this._running = false;
            this._update();
            if (!ok)
                Main.notifyError("Wifi-Hotspot-Toggle", (stderr || stdout || _("Unknown error")).trim());
        });
    }

    _showPassword() {
        this._run(["nmcli", "-s", "-g", "802-11-wireless-security.psk", "connection", "show", "id", this.connectionName],
            (ok, stdout, stderr) => {
                if (ok)
                    Main.notify("Wifi-Hotspot-Toggle", _("SSID: %s").format(this._getSsid() || "?") + "\n" + _("Password: %s").format(stdout.trim()));
                else
                    Main.notifyError("Wifi-Hotspot-Toggle", (stderr || _("Connection not found")).trim());
            });
    }

    _run(argv, callback) {
        try {
            const proc = Gio.Subprocess.new(argv,
                Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE);
            proc.communicate_utf8_async(null, null, (p, res) => {
                try {
                    const [, stdout, stderr] = p.communicate_utf8_finish(res);
                    callback(p.get_successful(), stdout || "", stderr || "");
                } catch (e) {
                    callback(false, "", e.message);
                }
            });
        } catch (e) {
            callback(false, "", e.message);
        }
    }

    on_applet_removed_from_panel() {
        for (let [ac, id] of this._acSignals)
            ac.disconnect(id);
        this._acSignals = [];
        if (this._client) {
            for (let id of this._clientSignals)
                this._client.disconnect(id);
        }
        this._clientSignals = [];
        this.settings.finalize();
    }
}

function main(metadata, orientation, panelHeight, instanceId) {
    return new HotspotApplet(metadata, orientation, panelHeight, instanceId);
}
