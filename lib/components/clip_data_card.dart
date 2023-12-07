import 'package:clipshare/entity/clip_data.dart';
import 'package:flutter/material.dart';

class ClipDataCard extends StatefulWidget {
  final ClipData clip;

  const ClipDataCard(this.clip, {super.key});

  @override
  State<StatefulWidget> createState() {
    return ClipDataCardState();
  }
}

class ClipDataCardState extends State<ClipDataCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      child: InkWell(
                        onTap: () {},
                        child: const Row(
                          children: [
                            Icon(Icons.home, size: 15),
                            SizedBox(
                              width: 2,
                            ),
                            Text("data")
                          ],
                        ),
                      ),
                    )
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
                        )
                      ],
                    )),
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
                    Text(widget.clip.timeStr)
                  ],
                ),
              ],
            )),
      ),
    );
  }
}
