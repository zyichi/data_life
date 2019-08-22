import 'package:data_life/views/my_date_picker_form_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:page_transition/page_transition.dart';
import 'package:flutter/cupertino.dart';

import 'package:percent_indicator/percent_indicator.dart';

import 'package:data_life/models/goal.dart';
import 'package:data_life/models/goal_action.dart';

import 'package:data_life/views/goal_action_edit.dart';
import 'package:data_life/views/labeled_text_form_field.dart';
import 'package:data_life/views/unique_check_form_field.dart';
import 'package:data_life/views/common_dialog.dart';
import 'package:data_life/views/type_to_str.dart';
import 'package:data_life/views/my_form_text_field.dart';

import 'package:data_life/blocs/goal_bloc.dart';


const double _kPickerSheetHeight = 216;


void _showGoalActionEditPage(
    BuildContext context, Goal goal, GoalAction goalAction, bool readOnly) {
  Navigator.push(
      context,
      PageTransition(
        child: GoalActionEdit(
          goal: goal,
          goalAction: goalAction,
          parentReadOnly: readOnly,
        ),
        type: PageTransitionType.rightToLeft,
      ));
}

class _GoalActionItem extends StatelessWidget {
  final Goal goal;
  final GoalAction goalAction;
  final bool parentReadOnly;
  const _GoalActionItem(
      {this.goal, this.goalAction, this.parentReadOnly = true})
      : assert(goal != null),
        assert(goalAction != null);

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.subhead;
    final statusStyle =
        Theme.of(context).textTheme.caption.copyWith(fontSize: 16.0);
    return InkWell(
      child: Padding(
        padding:
            const EdgeInsets.only(left: 0, top: 8.0, bottom: 8.0, right: 0),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 3,
              child: Row(
                children: <Widget>[
                  Text(goalAction.action.name, style: textStyle),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                TypeToStr.goalActionStatusToStr(goalAction.status, context),
                style: statusStyle,
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        _showGoalActionEditPage(context, goal, goalAction, parentReadOnly);
      },
    );
  }
}

class GoalEdit extends StatefulWidget {
  static const routeName = '/editGoal';

  final Goal goal;

  const GoalEdit({this.goal});

  @override
  _GoalEditState createState() {
    return new _GoalEditState();
  }
}

class _GoalEditState extends State<GoalEdit> {
  bool _isReadOnly = false;
  final Goal _goal = Goal();
  GoalBloc _goalBloc;

  final _formKey = GlobalKey<FormState>();

  final _nameFocusNode = FocusNode();

  String _title;
  double _progressPercent;
  String _howLong;
  String _customHowLong;

  @override
  void initState() {
    super.initState();

    if (widget.goal != null) {
      _isReadOnly = true;
      _goal.copy(widget.goal);
      _goal.goalActions = <GoalAction>[];
      for (var goalAction in widget.goal.goalActions) {
        _goal.goalActions.add(GoalAction.copeCreate(goalAction));
      }
      _title = '目标';
    } else {
      _title = '设立新目标';

      var now = DateTime.now();
      _goal.startTime =
          DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      _goal.stopTime = _goal.startTime + Duration(days: 7).inMilliseconds;
    }

    _progressPercent = _getProgressPercent();

    _goalBloc = BlocProvider.of<GoalBloc>(context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        centerTitle: true,
        actions: <Widget>[
          _createSaveAction(),
        ],
      ),
      floatingActionButton: _createFloatingActionButton(),
      body: SafeArea(
        top: false,
        bottom: false,
        child: BlocListener<GoalBloc, GoalState>(
          bloc: _goalBloc,
          listener: (context, state) {
            if (state is GoalActionAdded ||
                state is GoalActionDeleted ||
                state is GoalActionUpdated) {
              print('Goal action added/deleted/updated');
              setState(() {});
            }
          },
          child: Material(
            // color: Colors.grey[200],
            color: Colors.white,
            child: Form(
              key: _formKey,
              onWillPop: _onWillPop,
              child: ListView(
                children: <Widget>[
                  // _getGoalStatus(),
                  AbsorbPointer(
                    absorbing: _isReadOnly,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _createGoalNameField(),
                        SizedBox(height: 8),
                        Divider(),
                        SizedBox(height: 8),
                        _createTargetProgressField(),
                        SizedBox(height: 16),
                        Divider(),
                        _createTimeField(),
                      ],
                    ),
                  ),
                  Divider(),
                  _createGoalTaskField(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _createFloatingActionButton() {
    if (_isNewGoal) {
      return Container();
    }
    if (!_isReadOnly) {
      return Container();
    }
    if (_goal.status == GoalStatus.finished ||
        _goal.status == GoalStatus.expired) {
      return Container();
    }
    return FloatingActionButton(
      backgroundColor: Theme.of(context).primaryColor,
      onPressed: () {
        setState(() {
          _isReadOnly = false;
          _title = '修改目标';
        });
        FocusScope.of(context).requestFocus(_nameFocusNode);
      },
      child: Icon(
        Icons.edit,
      ),
    );
  }

  bool get _isNewGoal => widget.goal == null;

  bool _isNeedExitConfirm() {
    _updateGoalFromForm();
    if (_isNewGoal) {
      if (_goal.name.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } else {
      if (_isReadOnly) {
        return false;
      }
      if (_goal.isContentSameWith(widget.goal)) {
        return false;
      } else {
        return true;
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isNeedExitConfirm()) {
      return true;
    }
    return await CommonDialog.showEditExitConfirmDialog(
        context, 'Are you sure you want to discard your changes to the goal?');
  }

  void _nameChanged(String text) {
    _goal.name = text;
  }

  Widget _createGoalActionItem(Goal goal, GoalAction goalAction) {
    return InkWell(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, top: 8, right: 16, bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              goalAction.action.name,
              style: _fieldNameTextStyle(),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  TypeToStr.goalActionStatusToStr(goalAction.status, context),
                  style: TextStyle(color: _captionColor(context)),
                ),
                SizedBox(width: 0),
                Icon(
                  Icons.chevron_right,
                  color: _captionColor(context),
                ),
              ],
            ),
          ],
        ),
      ),
      onTap: () {
        _showGoalActionEditPage(context, _goal, goalAction, _isReadOnly);
      },
    );
  }

  Widget _createAddGoalActionItem() {
    return InkWell(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, top: 8, right: 16, bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              '添加新任务',
              style: _fieldNameTextStyle().copyWith(
                color: Theme.of(context).primaryColorDark,
              ),
            ),
            Icon(Icons.chevron_right,
                color: Theme.of(context).primaryColorDark),
          ],
        ),
      ),
      onTap: () {
        _showGoalActionEditPage(context, _goal, null, false);
      },
    );
  }

  Widget _emptyGoalActionItem() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8, right: 16, bottom: 8),
      child: Text(
        '无任务',
        style: _fieldNameTextStyle().copyWith(color: _captionColor(context)),
      ),
    );
  }

  Widget _buildGoalAction() {
    final toDoItems = <Widget>[];
    for (GoalAction goalAction in _goal.goalActions) {
      toDoItems.add(_createGoalActionItem(_goal, goalAction));
      toDoItems.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Divider(),
      ));
    }
    // Remove last divider
    if (_isReadOnly) {
      if (toDoItems.isNotEmpty) {
        toDoItems.removeLast();
      } else {
        toDoItems.add(_emptyGoalActionItem());
      }
      toDoItems.add(SizedBox(
        height: 8,
      ));
    } else {
      if (toDoItems.isEmpty) {
        toDoItems.add(_emptyGoalActionItem());
        toDoItems.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Divider(),
        ));
      }
      toDoItems.add(_createAddGoalActionItem());
      toDoItems.add(SizedBox(height: 8));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: toDoItems,
        ),
      ],
    );
  }

  void _updateGoalFromForm() {}

  void _editGoal() {
    _updateGoalFromForm();
    if (_isNewGoal) {
      _goalBloc.dispatch(
        AddGoal(goal: _goal),
      );
    } else {
      if (_goal.isContentSameWith(widget.goal)) {
        print('Same goal content, not need to update');
        return;
      }
      _goalBloc.dispatch(UpdateGoal(
        oldGoal: widget.goal,
        newGoal: _goal,
      ));
    }
  }

  Widget _getGoalStatus() {
    if (_goal.status == GoalStatus.ongoing) return Container();
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(top: 8),
      child: Center(
        child: Text(
          '${TypeToStr.goalStatusToStr(_goal.status, context)}',
          style: TextStyle(
            color: _goal.status == GoalStatus.finished
                ? Theme.of(context).primaryColorDark
                : Theme.of(context).accentColor,
          ),
        ),
      ),
    );
  }

  Widget _createCheckAction() {
    return IconButton(
      icon: Icon(Icons.check),
      onPressed: () {
        if (_formKey.currentState.validate()) {
          _editGoal();
          Navigator.of(context).pop();
        }
      },
    );
  }

  Widget _createSaveAction() {
    if (_isNewGoal) {
      return _createCheckAction();
    }
    if (_goal.status == GoalStatus.finished ||
        _goal.status == GoalStatus.expired) {
      return Container();
    }
    if (_isReadOnly) {
      return Container();
    }
    return _createCheckAction();
  }

  Color _captionColor(BuildContext context) {
    return Theme.of(context).textTheme.caption.color;
  }

  double _getProgressPercent() {
    if (_goal.progress == null || _goal.target == null || _goal.target == 0) {
      return 0.0;
    }
    double percent = _goal.progress / _goal.target;
    return percent;
  }

  String _getGoalProgressPercentStr(double percent) {
    return '${(percent * 100).toStringAsFixed(1)}%';
  }

  String _getNumDisplayStr(num num) {
    if (num == null) {
      return null;
    }
    int n = num.toInt();
    if ((num - n) == 0) {
      return n.toString();
    } else {
      return num.toString();
    }
  }

  Widget _createGoalNameField() {
    return Material(
      color: Colors.white,
      child: Padding(
        padding:
            const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 0),
        child: UniqueCheckFormField(
          initialValue: _goal.name,
          focusNode: _nameFocusNode,
          textStyle: Theme.of(context).textTheme.subhead.copyWith(fontSize: 24),
          validator: (String text, bool isUnique) {
            if (text.isEmpty) {
              return 'Goal name can not empty';
            }
            if (!isUnique && text != widget.goal?.name) {
              return 'Goal name already exist';
            }
            return null;
          },
          textChanged: _nameChanged,
          hintText: '输入目标名称',
          uniqueCheckCallback: (String text) {
            return _goalBloc.goalNameUniqueCheck(text);
          },
          autofocus: _isNewGoal,
        ),
      ),
    );
  }

  Widget _createTargetProgressField() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8, right: 16),
      child: Column(
        children: <Widget>[
          MyFormTextField(
            name: '目标值',
            inputHint: '输入目标值',
            initialValue: _getNumDisplayStr(_goal.target),
            valueMutable: !_isReadOnly,
            valueChanged: (String text) {
              num value = num.tryParse(text);
              setState(() {
                _goal.target = value ?? 0;
                _progressPercent = _getProgressPercent();
              });
            },
            validator: (String text) {
              if (text == null || text.isEmpty) {
                return '目标值不能为空';
              }
              var val = num.tryParse(text);
              if (val == null) {
                return '目标值必须是数字';
              }
              if (val <= 0) {
                return '目标值必须大于 0';
              }
              return null;
            },
          ),
          SizedBox(height: 8),
          MyFormTextField(
            name: '当前进度值',
            inputHint: '输入当前进度值',
            initialValue: _getNumDisplayStr(_goal.progress),
            valueMutable: !_isReadOnly,
            valueChanged: (String text) {
              num value = num.tryParse(text);
              setState(() {
                _goal.progress = value ?? 0;
                _progressPercent = _getProgressPercent();
              });
            },
            validator: (String text) {
              if (text == null || text.isEmpty) {
                return '当前进度值不能为空';
              }
              var val = num.tryParse(text);
              if (val == null) {
                return '当前进度值必须是数字';
              }
              if (val < 0) {
                return '当前进度值必须是正数';
              }
              return null;
            },
          ),
          SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '完成百分比 ${_getGoalProgressPercentStr(_progressPercent)}',
                style: Theme.of(context).textTheme.caption,
              ),
              SizedBox(height: 16),
              LinearPercentIndicator(
                percent: _progressPercent > 1 ? 1 : _progressPercent,
                lineHeight: 10,
                backgroundColor: Colors.grey[300],
                linearStrokeCap: LinearStrokeCap.butt,
                padding: EdgeInsets.symmetric(horizontal: 0),
                progressColor: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _createTimeField() {
    DateTime now = DateTime.now();
    return FormField(
      builder: (FormFieldState fieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(height: 16),
            MyDatePickerFormField(
              labelName: '开始时间',
              onChanged: (DateTime newDateTime) {
                fieldState.didChange(null);
                setState(() {
                  _goal.startDateTime = newDateTime;
                });
              },
              mutable: !_isReadOnly,
              initialDateTime: _goal.startDateTime,
              mode: CupertinoDatePickerMode.date,
              labelPadding: EdgeInsets.symmetric(horizontal: 16),
              valuePadding: EdgeInsets.symmetric(horizontal: 16),
            ),
            SizedBox(height: 8),
            MyDatePickerFormField(
              labelName: '结束时间',
              onChanged: (DateTime newDateTime) {
                fieldState.didChange(null);
                setState(() {
                  _goal.stopDateTime = newDateTime;
                });
              },
              mutable: !_isReadOnly,
              initialDateTime: _goal.stopDateTime,
              mode: CupertinoDatePickerMode.date,
              labelPadding: EdgeInsets.symmetric(horizontal: 16),
              valuePadding: EdgeInsets.symmetric(horizontal: 16),
            ),
            FormFieldError(
              errorText: fieldState.errorText,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: MyImmutableFormTextField(
                name: '目标时长',
                value: '${_goal.durationInDays} 天',
              ),
            ),
          ],
        );
      },
      autovalidate: true,
      validator: (value) {
        if (_isReadOnly) {
          return null;
        }
        var now = DateTime.now();
        var nowDate = DateTime(now.year, now.month, now.day);
        if (_isNewGoal) {
          if (_goal.startTime <
              nowDate.millisecondsSinceEpoch) {
            return '开始时间必须在当前时间之后';
          }
        }
        if (_goal.startTime > _goal.stopTime) {
          return '开始时间必须早于结束时间';
        }
        if (_goal.stopTime - _goal.startTime <
            Duration(days: 3).inMilliseconds) {
          return '时长必须大于三天';
        }
        return null;
      },
    );
  }

  Widget _createGoalTaskField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding:
              const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 0),
          child: Text(
            '任务',
            style: Theme.of(context).textTheme.caption,
          ),
        ),
        _buildGoalAction(),
      ],
    );
  }


  TextStyle _fieldNameTextStyle() {
    return TextStyle(
      fontSize: 16,
    );
  }

  Widget _createCustomHowLongWidget() {
    return Container(
      child: Column(
        children: <Widget>[
          Text('2 年 1 个月 15 天'),
          Row(
            children: <Widget>[
              Container(
                width: 60,
                child: TextField(
                  textAlign: TextAlign.center,
                  keyboardType:
                  TextInputType.numberWithOptions(signed: true),
                  decoration: InputDecoration(),
                  style: Theme.of(context).textTheme.subhead,
                  controller: TextEditingController(text: '1'),
                ),
              ),
              SizedBox(width: 16),
              Text('年'),
              SizedBox(width: 16),
              Container(
                width: 40,
                child: TextField(
                  textAlign: TextAlign.center,
                  keyboardType:
                  TextInputType.numberWithOptions(signed: true),
                  decoration: InputDecoration(),
                  style: Theme.of(context).textTheme.subhead,
                  controller: TextEditingController(text: '6'),
                ),
              ),
              SizedBox(width: 16),
              Text('个月'),
              SizedBox(width: 16),
              Container(
                width: 60,
                child: TextField(
                  textAlign: TextAlign.center,
                  keyboardType:
                  TextInputType.numberWithOptions(signed: true),
                  decoration: InputDecoration(),
                  style: Theme.of(context).textTheme.subhead,
                  controller: TextEditingController(text: '12'),
                ),
              ),
              SizedBox(width: 16),
              Text('天'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBottomPicker(Widget picker) {
    return Container(
      height: _kPickerSheetHeight,
      padding: const EdgeInsets.only(top: 6.0),
      color: CupertinoColors.white,
      child: DefaultTextStyle(
        style: const TextStyle(
          color: CupertinoColors.black,
          fontSize: 22.0,
        ),
        child: GestureDetector(
          // Blocks taps from propagating to the modal sheet and popping.
          onTap: () { },
          child: SafeArea(
            top: false,
            child: picker,
          ),
        ),
      ),
    );
  }

}
