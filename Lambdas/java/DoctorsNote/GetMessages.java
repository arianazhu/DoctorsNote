package DoctorsNote;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.google.gson.Gson;

import java.io.IOException;
import java.sql.*;
import java.util.ArrayList;
import java.util.Map;

/*
 * A Lambda handler for getting the most recent N messages in a given conversation.
 *
 * Expects: A JSON string that maps to a POJO of type GetOldMessagesRequest
 * Returns: A JSON string that maps from a POJO of type GetOldMessagesResponse
 *
 * Error Handling: Returns null if an unrecoverable error is encountered
 */
public class GetMessages implements RequestHandler<Map<String,Object>, Object> {
    private final String getMessagesFormatString = "SELECT content, messageID, timeCreated, sender FROM Message" +
            " WHERE conversationID=\"%s\" ORDER BY timeCreated DESC LIMIT %d;";

    public GetMessagesResponse handleRequest(Map<String,Object> jsonString, Context context) {
        try {
            Map<String, Object> body = (Map<String,Object>)jsonString.get("body");
            String conversationId = (body).get("conversationId").toString();
            int nMessages = Integer.parseInt((body).get("nMessages").toString());
            int startIndex = Integer.parseInt((body).get("startIndex").toString());
            long sinceWhen = Long.parseLong((body).get("sinceWhen").toString());
            GetMessagesRequest request = new GetMessagesRequest(conversationId, nMessages, startIndex, sinceWhen);

            // Establish connection with MariaDB
            Connection connection = getConnection();

            // Reading from database
            Statement statement = connection.createStatement();
            ResultSet messageResult = statement.executeQuery(String.format(getMessagesFormatString,
                    request.getConversationId(),
                    request.getnMessages()));

            // Processing results
            ArrayList<Message> messages = new ArrayList<>();
            while (messageResult.next()) {
                String content = messageResult.getString(1);
                String messageId = messageResult.getString(2);
                long timeSent = messageResult.getTimestamp(3).toInstant().getEpochSecond() * 1000;
                String sender = messageResult.getString(4);

                if (timeSent >= request.getSinceWhen()) {
                    messages.add(new Message(content, messageId, timeSent, sender));
                }
            }

            // Disconnect connection with shortest lifespan possible
            connection.close();

            Message[] tempArray = new Message[messages.size()];
            return new GetMessagesResponse(messages.toArray(tempArray));
        } catch (Exception e) {
            System.out.println(e.toString());
            return null;
        }
    }

    private Connection getConnection() {
        try {
            DBCredentialsProvider dbCP = new DBCredentialsProvider();
            Class.forName(dbCP.getDBDriver());     // Loads and registers the driver
            return DriverManager.getConnection(dbCP.getDBURL(),
                    dbCP.getDBUsername(),
                    dbCP.getDBPassword());
        } catch (IOException | SQLException | ClassNotFoundException e) {
            throw new NullPointerException("Failed to load connection in AddMessage:getConnection()");
        }
    }

    public class GetMessagesRequest {
        private String conversationId;
        private int nMessages;
        private int startIndex;
        private long sinceWhen;

        public GetMessagesRequest(String conversationId, int nMessages, int startIndex, long sinceWhen) {
            this.conversationId = conversationId;
            this.nMessages = nMessages;
            this.startIndex = startIndex;
            this.sinceWhen = sinceWhen;
        }

        public String getConversationId() {
            return conversationId;
        }

        public void setConversationId(String conversationId) {
            this.conversationId = conversationId;
        }

        public int getnMessages() {
            return nMessages;
        }

        public void setnMessages(int nMessages) {
            this.nMessages = nMessages;
        }

        public int getStartIndex() {
            return startIndex;
        }

        public void setStartIndex(int startIndex) {
            this.startIndex = startIndex;
        }

        public long getSinceWhen() {
            return sinceWhen;
        }

        public void setSinceWhen(long sinceWhen) {
            this.sinceWhen = sinceWhen;
        }
    }

    public class Message {
        private String content;
        private String messageId;
        private long timeSent;
        private String sender;

        public Message(String content, String messageId, long timeSent, String sender) {
            this.content = content;
            this.messageId = messageId;
            this.timeSent = timeSent;
            this.sender = sender;
        }

        public String getContent() {
            return content;
        }

        public void setContent(String content) {
            this.content = content;
        }

        public String getMessageId() {
            return messageId;
        }

        public void setMessageId(String messageId) {
            this.messageId = messageId;
        }

        public long getTimeSent() {
            return timeSent;
        }

        public void setTimeSent(long timeSent) {
            this.timeSent = timeSent;
        }

        public String getSender() {
            return sender;
        }

        public void setSender(String sender) {
            this.sender = sender;
        }
    }

    public class GetMessagesResponse {
        private Message[] messages;

        public GetMessagesResponse(Message[] messages) {
            this.messages = messages;
        }

        public Message[] getMessages() {
            return messages;
        }

        public void setMessages(Message[] messages) {
            this.messages = messages;
        }
    }

    public static void main(String[] args) {
        throw new IllegalStateException();
    }
}
