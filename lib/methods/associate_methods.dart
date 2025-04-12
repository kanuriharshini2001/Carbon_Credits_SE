import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AssociateMethods
{
 showsnacksBarMsg(String msg,BuildContext cxt)
 {
   var snakBar = SnackBar(content: Text(msg));
   ScaffoldMessenger.of(cxt).showSnackBar(snakBar);
 }
}