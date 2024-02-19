import 'package:clipshare/entity/clip_data.dart';
import 'package:flutter/material.dart';

class ClipDataCard extends StatefulWidget {
  final ClipData clip;
  final GestureTapCallback? onTap;

  const ClipDataCard(this.clip, {super.key, this.onTap});

  @override
  State<StatefulWidget> createState() {
    return ClipDataCardState();
  }
}

class ClipDataCardState extends State<ClipDataCard> {
  bool showSimpleTime = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: InkWell(
        onTap: () {
          widget.onTap?.call();
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    child: const Text("data"),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.clip.data.content,
                        textAlign: TextAlign.left,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  widget.clip.data.top
                      ? const Icon(Icons.push_pin, size: 16)
                      : const SizedBox(width: 0),
                  !widget.clip.data.sync
                      ? const Icon(
                          Icons.sync,
                          size: 16,
                          color: Colors.red,
                        )
                      : const SizedBox(width: 0),
                  GestureDetector(
                    child: Text(
                      showSimpleTime
                          ? widget.clip.timeStr
                          : widget.clip.data.time,
                    ),
                    onTap: () {
                      setState(() {
                        showSimpleTime = !showSimpleTime;
                      });
                    },
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 10),
                  ),
                  Text(widget.clip.sizeText),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
