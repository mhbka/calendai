import 'package:json_annotation/json_annotation.dart';
import 'package:namer_app/utils/datetime_converter.dart';

part 'outlook_email.g.dart';

/// An Outlook email.
@JsonSerializable(fieldRename: FieldRename.snake)
class OutlookEmailMessage {
  final String id;
  final OutlookEmailRecipient from;
  final String subject;
  final String bodyPreview;
  final String body;

  @DatetimeConverter()
  final DateTime sentDateTime;

  OutlookEmailMessage ({
    required this.id,
    required this.subject,
    required this.from,
    required this.bodyPreview,
    required this.body,
    required this.sentDateTime
  });

  factory OutlookEmailMessage.fromJson(Map<String, dynamic> json) => _$OutlookEmailMessageFromJson(json);
  Map<String, dynamic> toJson() => _$OutlookEmailMessageToJson(this);
}

/// Represents a sender/recipient of an Outlook email.
@JsonSerializable(fieldRename: FieldRename.snake)
class OutlookEmailRecipient {
  final OutlookEmailAddress emailAddress;

  OutlookEmailRecipient({ required this.emailAddress});

  factory OutlookEmailRecipient.fromJson(Map<String, dynamic> json) => _$OutlookEmailRecipientFromJson(json);
  Map<String, dynamic> toJson() => _$OutlookEmailRecipientToJson(this);
}

/// An Outlook email address.
@JsonSerializable(fieldRename: FieldRename.snake)
class OutlookEmailAddress {
  final String address;
  final String name;

  OutlookEmailAddress({ 
    required this.address,
    required this.name
  });

  factory OutlookEmailAddress.fromJson(Map<String, dynamic> json) => _$OutlookEmailAddressFromJson(json);
  Map<String, dynamic> toJson() => _$OutlookEmailAddressToJson(this);
}