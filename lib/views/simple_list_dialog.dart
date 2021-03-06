import 'package:flutter/material.dart';


typedef OnTapCallback<T> = void Function(T data, int index);

class SimpleListDialog extends StatefulWidget {
  final List<dynamic> items;
  final OnTapCallback onItemSelected;
  final EdgeInsets itemPadding;
  final int selectedIndex;

  const SimpleListDialog(
      {Key key,
        this.items,
        this.onItemSelected,
        this.selectedIndex = 0,
        this.itemPadding = const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
      })
      : super(key: key);

  @override
  _SimpleListDialogState createState() {
    return new _SimpleListDialogState();
  }
}

class _SimpleListDialogState extends State<SimpleListDialog> {
  @override
  void initState() {
    super.initState();
  }

  Widget _buildItemWidget(dynamic item, int index) {
    final itemStyle = Theme.of(context).textTheme.body1;
    return InkWell(
      child: Padding(
        padding: widget.itemPadding,
        child: Row(
          children: <Widget>[
            Expanded(flex: 8, child: Text(item.toString(), style: itemStyle,)),
            Expanded(
              flex: 1,
              child: widget.selectedIndex == index ? Icon(
                Icons.done,
              ) : SizedBox(width: 24.0, height: 24.0,),
            ),
          ],
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        widget.onItemSelected(item, index);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final views = <Widget>[];
    for (int i = 0; i < widget.items.length; i++) {
      views.add(_buildItemWidget(widget.items[i], i));
    }
    return SimpleDialog(
      contentPadding: EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0, bottom: 16.0),
      children: views,
    );
  }
}
