import 'package:flutter/material.dart';

class BoundaryBox extends StatelessWidget {
  final List<dynamic> results;
  final int previewH;
  final int previewW;
  final double screenH;
  final double screenW;

  const BoundaryBox(this.results, this.previewH, this.previewW, this.screenH, this.screenW);
  @override
  Widget build(BuildContext context) {
    List<Widget> _renderStrings() {
      return results.map((re) {
        return Stack(
          children: <Widget>[
            Positioned(
              bottom: -(screenH-80),
              width: screenW,
              height: screenH,
              child: Text(
                "${re["label"]=='0 with_mask'?"Mask detected":"Mask not detected"} ${(re["confidence"] * 100).toStringAsFixed(0)}%",
                textAlign: TextAlign.center,
                style: TextStyle(
                  backgroundColor: Colors.white,
                  color:re["label"]=='0 with_mask'? Colors.green:Colors.red,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              top: 20,
              width: screenW,
              height: screenH,
              child: Text(
                "Detecting vertically only",
                textAlign: TextAlign.center,
                style: TextStyle(
                  backgroundColor: Colors.black,
                  color:Colors.purple,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        );
      }).toList();
    }

    return Stack(
      children: _renderStrings(),
    );
  }
}
