/* Copyright (C) 2017 Tom Hartill

extension.js - Part of the NetSpeed Plus Gnome Shell Extension.

NetSpeed Plus is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 3 of the License, or (at your option) any later
version.

NetSpeed Plus is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
NetSpeed Plus; if not, see http://www.gnu.org/licenses/.

An up to date version can also be found at:
https://github.com/Tomha/gnome-shell-extension-netspeed-plus */

const GLib = imports.gi.GLib;
const St = imports.gi.St;

const Lang = imports.lang;
const Main = imports.ui.main;

const ExtensionUtils = imports.misc.extensionUtils;
const Me = ExtensionUtils.getCurrentExtension();
const Settings = Me.imports.settings;

function InterfaceData() {
    this._init();
}

InterfaceData.prototype = {
    _init() {
        this.initialReceived = 0;
        this.totalReceived = 0;
        this.lastReceived = 0;
        this.initialTransmitted = 0;
        this.totalTransmitted = 0;
        this.lastTransmitted = 0;
    }
};

function NetSpeedExtension() {
    this._init();
}

NetSpeedExtension.prototype = {
    _createLabelStyle: function (labelName) {
        let styleText = '';

        if (!!labelName) {
            let labelNames = ['down', 'up', 'total', 'usage'];
            let labelColours = [this._customSpeedDownColour,
                                this._customSpeedUpColour,
                                this._customSpeedTotalColour,
                                this._customUsageTotalColour];
            let labelIndex = labelNames.indexOf(labelName);
            if (labelIndex < 0) throw new Error ("Invalid label name.");
            else if (this._useCustomFontColours) styleText += ('color:' + labelColours[labelIndex] + ';');
        }
        if (this._useCustomFontFamily) styleText += ('font-family:' + this._customFontFamily + ';');
        if (this._useCustomFontSize > 0) styleText += ('font-size:' + this._customFontSize + 'pt;');
        if (this._useFixedWidth) {
            styleText += this._widthIsMinimum ? 'min-width:' : 'width:';
            styleText += this._customFixedWidth + 'px;';
        }
        styleText += 'text-align:right;';
        return styleText;
    },

    _formatSpeed: function (speed) {
        let unit = 0;
        while (speed >= 1000){
            speed /= 1000;
            unit += 1;
        }
        let text;
        if (speed == (speed | 0)) text = (speed.toString()); // If speed is int
        else text = (speed.toFixed(this._decimalPlace).toString());
        return text + ["B", "K", "M", "G"][unit];
    },


    _getBootTime: function () {
        // Accurate to +- 1 second due to rounding errors and processing time.
        let fileContentsRaw = GLib.file_get_contents('/proc/uptime');
        let fileContents = fileContentsRaw[1].toString().split(/\W+/);
        let upTime = parseInt(fileContents[0]);
        let date = new Date();
        let timeNow = parseInt(parseInt(date.getTime()) / 1000);
        return (timeNow - upTime);
    },

    _loadSettings: function() {
        this._customFixedWidth = this._settings.get_int('custom-fixed-width');
        this._customFontFamily = this._settings.get_string('custom-font-family');
        this._customFontSize = this._settings.get_int('custom-font-size');
        this._customSpeedDownColour =  this._settings.get_string('custom-speed-down-colour');
        this._customSpeedDownDecoration = this._settings.get_string('custom-speed-down-decoration');
        this._customSpeedTotalColour = this._settings.get_string('custom-speed-total-colour');
        this._customSpeedTotalDecoration = this._settings.get_string('custom-speed-total-decoration');
        this._customSpeedUpColour = this._settings.get_string('custom-speed-up-colour');
        this._customSpeedUpDecoration = this._settings.get_string('custom-speed-up-decoration');
        this._customUsageTotalColour = this._settings.get_string('custom-usage-total-colour');
        this._customUsageTotalDecoration = this._settings.get_string('custom-usage-total-decoration');
        this._decimalPlace = this._settings.get_int('decimal-place');
        this._displayVertical = this._settings.get_boolean('display-vertical');
        this._trackedInterfaces = this._settings.get_strv('interfaces');
        this._showSpeedDown = this._settings.get_boolean('show-speed-down');
        this._showSpeedTotal = this._settings.get_boolean('show-speed-total');
        this._showSpeedUp = this._settings.get_boolean('show-speed-up');
        this._showUsageTotal =this._settings.get_boolean('show-usage-total');
        this._updateInterval= this._settings.get_int('update-interval');
        this._useCustomDecorations = this._settings.get_boolean('use-custom-decorations');
        this._useCustomFontColours = this._settings.get_boolean('use-custom-font-colours');
        this._useCustomFontFamily = this._settings.get_boolean('use-custom-font-family');
        this._useCustomFontSize = this._settings.get_boolean('use-custom-font-size');
        this._useFixedWidth = this._settings.get_boolean('use-fixed-width');
        this._widthIsMinimum = this._settings.get_boolean('width-is-minimum');
    },

    _setAllLabelStyles: function () {
        this._downLabel.set_style(this._createLabelStyle('down'));
        this._upLabel.set_style(this._createLabelStyle('up'));
        this._totalLabel.set_style(this._createLabelStyle('total'));
        this._usageLabel.set_style(this._createLabelStyle('usage'));
    },

    _update: function () {
        this._updateInterfaceData();
        this._updateSpeeds();
        this._updateLabelText();

        if (this._runNum > this._currentRunNum){
            this._currentRunNum = this._runNum;
            Main.Mainloop.timeout_add_seconds(this._updateInterval, Lang.bind(this, this._update));
            return false;
        } else return this._isRunning;
    },

    _updateInterfaceData: function () {
        let fileContentsRaw = GLib.file_get_contents('/proc/net/dev');
        let fileContents = fileContentsRaw[1].toString().split('\n');
        for (let i = 2; i < fileContents.length; i++) { // i = 2 skips headers
            let lineData = fileContents[i].trim().split(/\W+/);
            let interfaceName = lineData[0];
            let interfaceIndex = this._interfaceNames.indexOf(interfaceName);
            if (interfaceIndex < 0) {
                let interfaceData = new InterfaceData();
                interfaceData.initialReceived = 0;
                interfaceData.totalReceived = 0;
                interfaceData.lastReceived = 0;
                interfaceData.initialTransmitted = 0;
                interfaceData.totalTransmitted = 0;
                interfaceData.lastTransmitted = 0;
                this._interfaceNames.push(interfaceName);
                this._interfaceData.push(interfaceData);
            } else {
                let interfaceData = this._interfaceData[interfaceIndex];
                interfaceData.lastReceived = interfaceData.totalReceived;
                interfaceData.lastTransmitted = interfaceData.totalTransmitted;
                interfaceData.totalReceived = lineData[1];
                interfaceData.totalTransmitted = lineData[9];
            }
        }
    },

    _updateLabelText: function() {
        if (this._showSpeedDown) {
            let speed = this._formatSpeed(this._speedDown);
            this._downLabel.set_text(speed + this._speedDownDecoration);
        }
        if (this._showSpeedUp) {
            let speed = this._formatSpeed(this._speedUp);
            this._upLabel.set_text(speed + this._speedUpDecoration);
        }
        if (this._showSpeedTotal) {
            let speed = this._formatSpeed(this._speedTotal);
            this._totalLabel.set_text(speed + this._speedTotalDecoration);
        }
        if (this._showUsageTotal) {
            let usage = this._formatSpeed(this._usageTotal);
            this._usageLabel.set_text(usage + this._usageTotalDecoration);
        }
    },

    _updateSpeeds: function () {
        let speedDown = speedUp = speedTotal = usageTotal = 0;
        for (let i = 0; i < this._trackedInterfaces.length; i++) {
            let interfaceName = this._trackedInterfaces[i];
            let interfaceIndex = this._interfaceNames.indexOf(interfaceName);
            if (interfaceIndex < 0) continue; // This shouldn't happen
            let interfaceData = this._interfaceData[interfaceIndex];
            let justReceived = interfaceData.totalReceived - interfaceData.lastReceived;
            let justTransmitted = interfaceData.totalTransmitted - interfaceData.lastTransmitted;

            speedDown += justReceived;
            speedUp += justTransmitted;
            speedTotal += (justReceived + justTransmitted);

            let totalDown = interfaceData.totalReceived - interfaceData.initialReceived;
            let totalUp = interfaceData.totalTransmitted - interfaceData.initialTransmitted;

            usageTotal += (totalDown + totalUp);
        }
        this._speedDown = speedDown / this._updateInterval;
        this._speedUp = speedUp / this._updateInterval;
        this._speedTotal = speedTotal / this._updateInterval;
        this._usageTotal = usageTotal;
    },

    _onButtonClicked: function (button, event) {
        if (event.get_button() == 3) {  // Clear counter on right click
            for(let i = 0; i < this._interfaceData.length; i++) {
                this._interfaceData[i].initialReceived = this._interfaceData[i].totalReceived;
                this._interfaceData[i].initialTransmitted = this._interfaceData[i].totalTransmitted;
            }
            this._usageLabel.set_text("0B" + this._usageTotalDecoration);
        }
    },

    _onSettingsChanged: function (settings, key) {
        switch(key) {
            case 'custom-fixed-width':
                this._customFixedWidth = settings.get_int('custom-fixed-width');
                this._setAllLabelStyles();
                this._downLabel.set_text('');
                this._upLabel.set_text('');
                this._totalLabel.set_text('');
                this._usageLabel.set_text('');
                this._updateLabelText();
                break;
            case 'custom-font-family':
                this._customFontFamily = settings.get_string('custom-font-family');
                this._setAllLabelStyles();
                break;
            case 'custom-font-size':
                this._customFontSize = settings.get_int('custom-font-size');
                this._setAllLabelStyles();
                break;
            case 'custom-speed-down-colour':
                this._customSpeedDownColour = tsettings.get_string('custom-speed-down-colour');
                this._downLabel.set_style(this._createLabelStyle('down'));
                break;
            case 'custom-speed-down-decoration':
                this._speedDownDecoration = this._useCustomDecorations ?
                    settings.get_string('custom-speed-down-decoration') : '↓';
                this._setAllLabelStyles();
                break;
            case 'custom-speed-total-colour':
                this._customSpeedTotalColour = settings.get_string('custom-speed-total-colour');
                this._totalLabel.set_style(this._createLabelStyle('total'));
                break;
            case 'custom-speed-total-decoration':
                this._speedTotalDecoration = this._useCustomDecorations ?
                    settings.get_string('custom-speed-total-decoration') : '⇵';
                this._setAllLabelStyles();
                break;
            case 'custom-speed-up-colour':
                this._customSpeedUpColour = settings.get_string('custom-speed-up-colour');
                this._upLabel.set_style(this._createLabelStyle('up'));
                break;
            case 'custom-speed-up-decoration':
                this._speedUpDecoration = this._useCustomDecorations ?
                    settings.get_string('custom-speed-up-decoration') : '↑';
                this._setAllLabelStyles();
                break;
            case 'custom-usage-total-colour':
                this._customUsageTotalColour = settings.get_string('custom-usage-total-colour');
                this._usageLabel.set_style(this._createLabelStyle('usage'));
                break;
            case 'custom-usage-total-decoration':
                this._usageTotalDecoration = this._useCustomDecorations ?
                    settings.get_string('custom-usage-total-decoration') : 'Σ';
                this._setAllLabelStyles();
                break;
            case 'decimal-place':
                this._decimalPlace = settings.get_int('decimal-place');
                break;
            case 'display-vertical':
                this._displayVertical = settings.get_boolean('display-vertical');
                this._labelBox.set_vertical(this._displayVertical);
                break;
            case 'interfaces':
                this._trackedInterfaces = settings.get_strv('interfaces');
                break;
            case 'show-speed-down':
                this._showSpeedDown = settings.get_boolean('show-speed-down')
                if (this._showSpeedDown) this._downLabel.show()
                else this._downLabel.hide();
                break;
            case 'show-speed-total':
                this._showSpeedTotal = settings.get_boolean('show-speed-total')
                if (this._showSpeedTotal) this._totalLabel.show()
                else this._totalLabel.hide();
                break;
            case 'show-speed-up':
                this._showSpeedUp = settings.get_boolean('show-speed-up')
                if (this._showSpeedUp) this._upLabel.show()
                else this._upLabel.hide();
                break;
            case 'show-usage-total':
                this._showUsageTotal = settings.get_boolean('show-usage-total')
                if (this._showUsageTotal) this._usageLabel.show()
                else this._usageLabel.hide();
                break;
            case 'update-interval':
                this._updateInterval = settings.get_int('update-interval');
                this._runNum++;
                break;
            case 'use-custom-font-colours':
                this._useCustomFontColours = settings.get_boolean('use-custom-font-colours');
                this._setAllLabelStyles();
                break;
            case 'use-custom-decorations':
                this._useCustomDecorations = settings.get_boolean('use-custom-decorations');
                if (this._useCustomDecorations) {
                    this._speedDownDecoration = settings.get_string('custom-speed-down-decoration');
                    this._speedUpDecoration = settings.get_string('custom-speed-up-decoration');
                    this._speedTotalDecoration = settings.get_string('custom-speed-total-decoration');
                    this._usageTotalDecoration = settings.get_string('custom-usage-total-decoration');
                } else {
                    this._speedDownDecoration =  '↓';
                    this._speedUpDecoration = '↑';
                    this._speedTotalDecoration = '⇵';
                    this._usageTotalDecoration = 'Σ';
                }
                this._setAllLabelStyles();
                break;
            case 'use-custom-font-family':
                this._useCustomFontFamily = settings.get_boolean('use-custom-font-family');
                this._setAllLabelStyles();
                break;
            case 'use-custom-font-size':
                this._useCustomFontSize = settings.get_boolean('use-custom-font-size');
                this._setAllLabelStyles();
                break;
            case 'use-fixed-width':
                this._useFixedWidth = settings.get_boolean('use-fixed-width');
                this._setAllLabelStyles();
                break;
            case 'width-is-minimum':
                this._widthIsMinimum = settings.get_boolean('width-is-minimum');
                this._setAllLabelStyles();
                break;
        }
    },

    _init: function () { },

    enable: function () {
        this._settings = Settings.getSettings();
        this._settingsSignal = this._settings.connect('changed', Lang.bind(this, this._onSettingsChanged));

        this._loadSettings();

        this._isRunning = true;
        this._runNum = 1;
        this._currentRunNum = 0;

        this._labelBox = new St.BoxLayout();
        this._button = new St.Bin({style_class: 'panel-button',
                                   reactive: true,
                                   can_focus: true,
                                   x_fill: true,
                                   y_fill: false,
                                   track_hover: true,
                                   child: this._labelBox})

        this._buttonSignal = this._button.connect('button-press-event', Lang.bind(this, this._onButtonClicked));

        this._downLabel = new St.Label();
        this._upLabel = new St.Label();
        this._totalLabel = new St.Label();
        this._usageLabel = new St.Label();

        this._labelBox.add_child(this._downLabel);
        this._labelBox.add_child(this._upLabel);
        this._labelBox.add_child(this._totalLabel);
        this._labelBox.add_child(this._usageLabel);

        this._speedDownDecoration = this._useCustomDecorations ? this._customSpeedDownDecoration : '↓';
        this._speedUpDecoration = this._useCustomDecorations ? this._customSpeedUpDecoration : '↑';
        this._speedTotalDecoration = this._useCustomDecorations ? this._customSpeedTotalDecoration : '⇵';
        this._usageTotalDecoration = this._useCustomDecorations ? this._customUsageTotalDecoration : 'Σ';

        this._setAllLabelStyles();

        this._showSpeedDown ? this._downLabel.show() : this._downLabel.hide();
        this._showSpeedUp ? this._upLabel.show() : this._upLabel.hide();
        this._showSpeedTotal ? this._totalLabel.show() : this._totalLabel.hide();
        this._showUsageTotal ? this._usageLabel.show() : this._usageLabel.hide();

        this._labelBox.set_vertical(this._displayVertical);

        this._speedDown = 0;
        this._speedUp = 0;
        this._speedTotal = 0;
        this._usageTotal = 0;

        this._interfaceNames = [];
        this._interfaceData = [];

        let lastBootTime = this._settings.get_int('last-boot-time');
        let thisBootTime = this._getBootTime();
        let timeDiff = thisBootTime - lastBootTime;

        if (timeDiff > 1 || timeDiff < -1) { // timeDiff accurate to +- 1 second
            this._settings.set_int('last-boot-time', thisBootTime);
            this._settings.apply();
        } else {
            let initialReceivedValues = this._settings.get_strv('initial-receive-counts');
            let initialTransmittedValues = this._settings.get_strv('initial-transmit-counts');

            // This won't work with different lengths, so give up.
            if (!initialReceivedValues.length == initialTransmittedValues.length == this._trackedInterfaces.length) {
                Main.panel._rightBox.insert_child_at_index(this._button, 0);
                this._update();
                return;
            }

            this._updateInterfaceData();

            for (let i = 0; i < this._trackedInterfaces.length; i++) {
                let name = this._trackedInterfaces[i];
                let index = this._interfaceNames.indexOf(name);
                let interfaceData = this._interfaceData[index];

                let initialReceived =  parseInt(initialReceivedValues[i]);
                let initialTransmitted = parseInt(initialTransmittedValues[i]);

                // Only set new initial values if they are older
                if (initialReceived > interfaceData.initialReceived &&
                        initialTransmitted > interfaceData.initialTransmitted) {
                    interfaceData.initialReceived = initialReceived;
                    interfaceData.initialTransmitted = initialTransmitted;
                }
            }
        }

        Main.panel._rightBox.insert_child_at_index(this._button, 0);
        this._update();
    },

    disable: function () {
        this._isRunning = false;

        this._settings.disconnect(this._settingsSignal);
        this._button.disconnect(this._buttonSignal);

        Main.panel._rightBox.remove_child(this._button);

        this._downLabel.destroy();
        this._upLabel.destroy();
        this._totalLabel.destroy();
        this._usageLabel.destroy();
        this._button.destroy();
        this._labelBox.destroy();

        let initialReceivedValues = [];
        let initialTransmittedValues = [];
        for (let i = 0; i < this._trackedInterfaces.length; i++) {
            let name = this._trackedInterfaces[i];
            let index = this._interfaceNames.indexOf(name);
            if (index < 0) continue;
            let received = this._interfaceData[index].initialReceived;
            let transmitted = this._interfaceData[index].initialTransmitted;
            initialReceivedValues.push(received.toString());
            initialTransmittedValues.push(transmitted.toString());
        }
        this._settings.set_strv('initial-receive-counts', initialReceivedValues);
        this._settings.set_strv('initial-transmit-counts', initialTransmittedValues);
        this._settings.apply();
    }
};

function init() {
    return new NetSpeedExtension();
}

