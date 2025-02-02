import '../entities/message.dart';

abstract class ChatRepository {
  Stream<String> generateResponse(String prompt);
  Future<void> saveMessage(Message message);
  List<Message> getMessages();
}
