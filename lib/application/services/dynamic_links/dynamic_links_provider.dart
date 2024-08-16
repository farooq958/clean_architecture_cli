import 'package:share_plus/share_plus.dart';

class DynamicLink {
  static createDynamicLinks({String? id}) async {
    /// in link first is domain link and id is the unique identifier of the specific page in the case
    /// its business id we are sharing business to other on WhatsApp or any other chatting side

    String link = "https://yourapplink.com?$id";
    await Share.share(link);
  }
}
