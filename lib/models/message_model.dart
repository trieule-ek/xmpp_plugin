// [The file has been modified by eKadence]

class MessageChat {
  String? customText;
  String? from;
  String? senderJid;
  String? time;
  String? id;
  String? type;
  String? body;
  String? msgtype;
  String? bubbleType;
  String? mediaURL;
  int? isReadSent;
  String? delayTime;
  String? chatStateType;
  String? subject;

  MessageChat({
    this.customText,
    this.from,
    this.senderJid,
    this.time,
    this.id,
    this.type,
    this.body,
    this.msgtype,
    this.bubbleType,
    this.mediaURL,
    this.isReadSent,
    this.delayTime,
    this.chatStateType,
    this.subject,
  });

  bool get hasSubject => subject != null && subject!.trim() != "";

  Map<String, dynamic> toEventData() {
    return {
      'customText': customText,
      'from': from,
      'senderJid': senderJid,
      'time': time,
      'id': id,
      'type': type,
      'body': body,
      'msgtype': msgtype,
      'bubbleType': bubbleType,
      'mediaURL': mediaURL,
      'isReadSent': isReadSent,
      'delayTime': delayTime,
      'chatStateType': chatStateType,
      'subject': subject,
    };
  }

  factory MessageChat.fromJson(dynamic eventData) {
    return MessageChat(
      customText: eventData['customText'] ?? '',
      from: eventData['from'] ?? '',
      senderJid: eventData['senderJid'] ?? '',
      time: eventData['time'] ?? '0',
      isReadSent: eventData['isReadSent'] ?? 0,
      id: eventData['id'] ?? '',
      type: eventData['type'] ?? '',
      body: eventData['body'] ?? '',
      msgtype: eventData['msgtype'] ?? '',
      bubbleType: eventData['bubbleType'] ?? '',
      mediaURL: eventData['mediaURL'] ?? '',
      delayTime: eventData['delayTime'] ?? '',
      chatStateType: eventData['chatStateType'] ?? '',
      subject: (eventData['subject'] ?? "") == "" ? "" : "[[CHANGE_GROUP_NAME]]${eventData['subject'] ?? ""}[[/CHANGE_GROUP_NAME]]",
    );
  }
}
