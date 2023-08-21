import 'package:flutter/material.dart';
import 'package:katya/domain/user/model.dart';
import 'package:katya/global/dimensions.dart';
import 'package:katya/global/strings.dart';
import 'package:katya/views/widgets/buttons/button-text.dart';

class DialogExplaination extends StatelessWidget {
  const DialogExplaination({
    super.key,
    this.user,
    this.title = '',
    this.content = '',
    this.onConfirm,
  });

  final User? user;
  final String title;
  final String content;
  final Function? onConfirm;

  @override
  Widget build(BuildContext context) => SimpleDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(title),
        titlePadding: Dimensions.dialogPadding,
        contentPadding: Dimensions.dialogPadding,
        children: <Widget>[
          Text(content),
          Container(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ButtonText(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  textWidget: Text(
                    Strings.buttonConfirm,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          )
        ],
      );
}
