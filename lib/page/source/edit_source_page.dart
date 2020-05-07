import 'dart:convert';

import 'package:eso/database/rule.dart';
import 'package:eso/global.dart';
import 'package:eso/page/source/edit_rule_page.dart';
import 'package:flutter/material.dart';
import 'package:toast/toast.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart' as http;

//图源编辑
class EditSourcePage extends StatefulWidget {
  @override
  _EditSourcePageState createState() => _EditSourcePageState();
}

class _EditSourcePageState extends State {
  @override
  void initState() {
    _updateView();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('站点管理'),
        actions: [
          _buildpopupMenu(context),
        ],
      ),
      body: FutureBuilder<List<Rule>>(
        future: Global.ruleDao.findAllRules(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.data.length == 0) {
            return Center(
              child: Text(
                '请点击右上角添加规则',
                style: TextStyle(color: Colors.grey[700]),
              ),
            );
          }
          final rules = snapshot.data;
          return ListView.builder(
            itemCount: rules.length,
            //padding: EdgeInsets.all(10),
            physics: BouncingScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              return _buildItem(context, rules[index], index);
            },
          );
        },
      ),
    );
  }

  bool _isloadFromYiciYuan = false;
  Future<void> fromYiciYuan(BuildContext context) async {
    await Global.ruleDao.deleteRules(await Global.ruleDao.findAllRules());
    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        child: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: "输入源地址, 回车开始导入",
            contentPadding: EdgeInsets.symmetric(horizontal: 12),
          ),
          enabled: !_isloadFromYiciYuan,
          onSubmitted: (url) async {
            setState(() {
              _isloadFromYiciYuan = true;
            });
            url = url.trim();
            Toast.show("输入的地址为$url", context);
            try {
              final res = await http.get("$url");
              final json = jsonDecode(utf8.decode(res.bodyBytes));
              if (json is Map) {
                await Global.ruleDao
                    .insertOrUpdateRule(Rule.fromYiCiYuan(json));
              } else if (json is List) {
                await Global.ruleDao.insertOrUpdateRules(
                    json.map((rule) => Rule.fromYiCiYuan(rule)).toList());
              }
            } catch (e) {
              Toast.show("$e", context);
            }
            _isloadFromYiciYuan = false;
            Navigator.pop(context);
            setState(() {});
          },
        ),
      ),
    );
  }

  PopupMenuButton _buildpopupMenu(BuildContext context) {
    const ADD_RULE = 0;
    const FROM_CLIPBOARD = 1;
    const FROM_FILE = 2;
    const FROM_CLOUD = 3;
    const FROM_YICIYUAN = 4;
    final primaryColor = Theme.of(context).primaryColor;
    return PopupMenuButton<int>(
      elevation: 20,
      icon: Icon(Icons.add),
      offset: Offset(0, 40),
      onSelected: (int value) {
        switch (value) {
          case ADD_RULE:
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => EditRulePage()));
            break;
          case FROM_CLIPBOARD:
            Toast.show("从剪贴板导入", context);
            break;
          case FROM_FILE:
            Toast.show("从本地文件导入", context);
            break;
          case FROM_CLOUD:
            Toast.show("从网络导入", context);
            break;
          case FROM_YICIYUAN:
            fromYiciYuan(context);
            break;
          default:
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
        PopupMenuItem(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('新建规则'),
              Icon(
                Icons.code,
                color: primaryColor,
              ),
            ],
          ),
          value: ADD_RULE,
        ),
        PopupMenuItem(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('从异次元源链接导入'),
              Icon(
                Icons.cloud_download,
                color: primaryColor,
              ),
            ],
          ),
          value: FROM_YICIYUAN,
        ),
        PopupMenuItem(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('从剪贴板导入'),
              Icon(
                Icons.content_paste,
                color: primaryColor,
              ),
            ],
          ),
          value: FROM_CLIPBOARD,
        ),
        PopupMenuItem(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('文件导入'),
              Icon(
                Icons.file_download,
                color: primaryColor,
              ),
            ],
          ),
          value: FROM_FILE,
        ),
        PopupMenuItem(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('网络导入'),
              Icon(
                Icons.cloud_download,
                color: primaryColor,
              ),
            ],
          ),
          value: FROM_CLOUD,
        ),
      ],
    );
  }

  Widget _buildItem(BuildContext context, Rule rule, int index) {
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.25,
      child: GestureDetector(
        onTap: () {
          Toast.show(rule.name, context);
        },
        child: CheckboxListTile(
          value: rule.enableSearch,
          activeColor: Theme.of(context).primaryColor,
          title: Text('${rule.name}'),
          subtitle: Text('${rule.host}'),
          onChanged: (bool val) {
            rule.enableSearch = val;
            Global.ruleDao.insertOrUpdateRule(rule);
            _updateView();
          },
        ),
      ),
      actions: [
        IconSlideAction(
          caption: '置顶',
          color: Colors.blueGrey,
          icon: Icons.vertical_align_top,
          onTap: () async {
            Rule maxSort = await Global.ruleDao.findMaxSort();

            rule.sort = maxSort.sort + 1;
            Global.ruleDao.insertOrUpdateRule(rule);
            _updateView();
          },
        ),
      ],
      secondaryActions: <Widget>[
        IconSlideAction(
          caption: '编辑',
          color: Colors.black45,
          icon: Icons.create,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => EditRulePage(
                    rule: rule,
                  ))),
        ),
        IconSlideAction(
          caption: '删除',
          color: Colors.red,
          icon: Icons.delete,
          onTap: () {
            Global.ruleDao.deleteRule(rule);
            _updateView();
          },
        ),
      ],
    );
  }

  void _updateView() {
    setState(() {});
  }
}