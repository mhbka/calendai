// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outlook_email.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OutlookEmailMessage _$OutlookEmailMessageFromJson(Map<String, dynamic> json) =>
    OutlookEmailMessage(
      id: json['id'] as String,
      subject: json['subject'] as String,
      from: OutlookEmailRecipient.fromJson(
        json['from'] as Map<String, dynamic>,
      ),
      bodyPreview: json['body_preview'] as String,
      body: json['body'] as String,
      sentDateTime: const DatetimeConverter().fromJson(
        json['sent_date_time'] as String,
      ),
    );

Map<String, dynamic> _$OutlookEmailMessageToJson(
  OutlookEmailMessage instance,
) => <String, dynamic>{
  'id': instance.id,
  'from': instance.from,
  'subject': instance.subject,
  'body_preview': instance.bodyPreview,
  'body': instance.body,
  'sent_date_time': const DatetimeConverter().toJson(instance.sentDateTime),
};

OutlookEmailRecipient _$OutlookEmailRecipientFromJson(
  Map<String, dynamic> json,
) => OutlookEmailRecipient(
  emailAddress: OutlookEmailAddress.fromJson(
    json['email_address'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$OutlookEmailRecipientToJson(
  OutlookEmailRecipient instance,
) => <String, dynamic>{'email_address': instance.emailAddress};

OutlookEmailAddress _$OutlookEmailAddressFromJson(Map<String, dynamic> json) =>
    OutlookEmailAddress(
      address: json['address'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$OutlookEmailAddressToJson(
  OutlookEmailAddress instance,
) => <String, dynamic>{'address': instance.address, 'name': instance.name};
