import 'package:device_preview/src/devices/devices.dart';
import 'package:device_preview/src/tool_bar/button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// import '../../../device_preview.dart';
import 'package:device_preview/device_preview.dart';
import '../../utilities/spacing.dart';
import 'popover.dart';

class DevicesPopOver extends StatefulWidget {
  @override
  _DevicesPopOverState createState() => _DevicesPopOverState();
}

class _DevicesPopOverState extends State<DevicesPopOver> {
  List<TargetPlatform> selected;

  final TextEditingController _searchTEC = TextEditingController();
  String _searchedText = '';

  @override
  void initState() {
    _searchTECListener();
    super.initState();
  }

  void _searchTECListener() {
    _searchTEC.addListener(() {
      setState(() {
        _searchedText = _searchTEC.text.replaceAll(' ', '').toLowerCase();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final preview = DevicePreview.of(context);
    final all =
        preview.availableDevices.map((e) => e.platform).toSet().toList();
    final selected = this.selected ?? [preview.device?.platform ?? all.first];

    return GestureDetector(
      onPanDown: (_) {
        FocusScope.of(context).requestFocus(FocusNode()); //remove search focus
      },
      child: Column(
        children: <Widget>[
          PlatformSelector(
            all: all,
            selected: selected,
            onChanged: (v) => setState(() {
              _clearSearchTEC();
              this.selected = v;
            }),
          ),
          DeviceSearchField(
            _searchTEC,
            onClear: _clearSearchTEC,
          ),
          Expanded(
            child: ListView(
              key: Key('DevicesListView'),
              padding: EdgeInsets.all(10.0),              
              children: preview.availableDevices
                  .where((x) =>
                      selected.contains(x.platform) &&
                      x.name
                          .replaceAll(' ', '')
                          .toLowerCase()
                          .contains(_searchedText))
                  .map((e) => DeviceTile(e, () {
                    preview.device = e;
                    if(preview.closeOnSelection) {
                      Popover.close(context);
                    }
                  }))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _clearSearchTEC() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchTEC.clear());
  }
}

class PlatformSelector extends StatelessWidget {
  final List<TargetPlatform> all;
  final List<TargetPlatform> selected;
  final ValueChanged<List<TargetPlatform>> onChanged;

  const PlatformSelector({
    @required this.all,
    @required this.selected,
    @required this.onChanged,
  });

  IconData platformIcon(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.android:
        return FontAwesomeIcons.android;
      case TargetPlatform.iOS:
        return FontAwesomeIcons.apple;
      case TargetPlatform.fuchsia:
        return FontAwesomeIcons.google;
      /*case TargetPlatform.macOS:
        return FontAwesomeIcons.appleAlt;
      case TargetPlatform.windows:
        return FontAwesomeIcons.windows;*/
      default:
        return FontAwesomeIcons.mobile;
    }
  }

  @override
  Widget build(BuildContext context) {
    final toolBarStyle = DevicePreviewTheme.of(context).toolBar;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10.0),
      color: toolBarStyle.backgroundColor,
      child: Row(
        children: all
            .map<Widget>((x) {
              final isSelected = selected.contains(x);
              final identifier = normalize(x.toString());
              return ToolBarButton(
                key: Key('PlatformSelector${identifier}Button'),
                backgroundColor: isSelected ? theme.accentColor : null,
                foregroundColor:
                    isSelected ? theme.accentTextTheme.button.color : null,
                icon: platformIcon(x),
                onTap: () {
                  onChanged([x]);
                },
              );
            })
            .toList()
            .spaced(horizontal: 8.0),
      ),
    );
  }

  String normalize(String string) {
    var parts = string.split('.');
    return parts[1][0].toUpperCase() + parts[1].substring(1);
  }

}

class DeviceTile extends StatelessWidget {
  final Device device;
  final GestureTapCallback onTap;

  DeviceTile(this.device, this.onTap);

  IconData _icon() {
    switch (device.type) {
      case DeviceType.tablet:
        return Icons.tablet_android;
        break;
      case DeviceType.watch:
        return Icons.watch;
        break;
      case DeviceType.desktop:
        return Icons.desktop_mac;
        break;
      case DeviceType.tv:
        return Icons.tv;
        break;
      case DeviceType.freeform:
        return Icons.photo_size_select_small;
        break;
      default:
        return Icons.phone_android;
        break;
    }
  }

  String _type() {
    switch (device.type) {
      case DeviceType.tablet:
        return 'Tablet';
        break;
      case DeviceType.watch:
        return 'Watch';
        break;
      case DeviceType.desktop:
        return 'Desktop';
        break;
      case DeviceType.tv:
        return 'TV';
        break;
      case DeviceType.freeform:
        return 'Freeform';
        break;
      default:
        return 'Phone';
        break;
    }
  }

  String _description() {
    if (device.type == DeviceType.freeform) return _type();
    return '${_type()} - ${device.portrait.size.width}x${device.portrait.size.height} - @${device.portrait.devicePixelRatio}';
  }

  @override
  Widget build(BuildContext context) {
    final preview = DevicePreview.of(context);
    final isSelected = preview.device.name == device.name;
    final toolBarStyle = DevicePreviewTheme.of(context).toolBar;

    return GestureDetector(
      onTap: !isSelected ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              Container(
                width: 12,
                child: Icon(
                  _icon(),
                  size: 12.0,
                  color: toolBarStyle.foregroundColor,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      device.name,
                      style: TextStyle(
                          fontSize: 12.0, color: toolBarStyle.foregroundColor),
                    ),
                    Text(
                      _description(),
                      style: TextStyle(
                        fontSize: 11.0,
                        color: toolBarStyle.foregroundColor.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DeviceSearchField extends StatelessWidget {
  final TextEditingController searchTEC;
  final VoidCallback onClear;
  const DeviceSearchField(this.searchTEC, {Key key, @required this.onClear})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final toolBarStyle = DevicePreviewTheme.of(context).toolBar;
    return Container(
      child: Material(
        child: Container(
          color: toolBarStyle.backgroundColor,
          height: 48,
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
          child: TextField(
            key: Key('DeviceSearchField'),
            style: TextStyle(color: toolBarStyle.foregroundColor, fontSize: 12),
            controller: searchTEC,
            decoration: InputDecoration(
                hintStyle:
                    const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
                hintText: 'Search by device name...',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                ),
                filled: true,
                fillColor: toolBarStyle.foregroundColor.withOpacity(0.12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                prefixIcon: const Icon(FontAwesomeIcons.search, size: 12),
                suffix: InkWell(
                  child: Icon(
                    FontAwesomeIcons.times,
                    size: 12,
                    color: Theme.of(context).primaryColor,
                  ),
                  onTap: onClear,
                )),
          ),
        ),
      ),
    );
  }
}
