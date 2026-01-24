import { App, Widget } from 'resource:///com/github/Aylur/ags/widget.js';
import { execAsync, date } from 'resource:///com/github/Aylur/ags/utils.js';

// Simple top bar
const Bar = () => Widget.Window({
    name: 'bar',
    className: 'bar',
    anchor: ['top', 'left', 'right'],
    exclusivity: 'exclusive',
    child: Widget.CenterBox({
        startWidget: Widget.Label({ label: 'Niri + AGS' }),
        centerWidget: Widget.Label({ label: date('%H:%M %a') }),
        endWidget: Widget.Button({
            label: 'Power',
            onClicked: () => execAsync('systemctl poweroff'),
        }),
    }),
});

// Calendar popup (toggle with ags -t calendar)
const CalendarPopup = () => Widget.Window({
    name: 'calendar',
    className: 'calendar-popup',
    visible: false,
    anchor: ['top'],
    child: Widget.Calendar({ showDetails: true }),
});

App.addWindow(Bar());
App.addWindow(CalendarPopup());

print("Minimal AGS loaded!");