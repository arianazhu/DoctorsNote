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
public class GetMessages implements RequestHandler<Map<String,Object>, GetMessages.GetMessagesResponse> {
    private final String getMessagesFormatString = "SELECT content, messageID, timeCreated, sender FROM Message" +
            " WHERE conversationID = ? ORDER BY timeCreated DESC LIMIT ?;";

    public GetMessagesResponse handleRequest(Map<String,Object> inputMap, Context context) {
        try {
            System.out.println("Getting messages");
            // Converting the passed JSON string into a POJO
            Gson gson = new Gson();
            //GetMessagesRequest request = gson.fromJson(jsonString, GetMessagesRequest.class);

            // Establish connection with MariaDB
            DBCredentialsProvider dbCP;
            Connection connection = getConnection();

            // Reading from database
            PreparedStatement statement = connection.prepareStatement(getMessagesFormatString);
            statement.setString(1, (String)((Map<String,Object>) inputMap.get("body-json")).get("conversationID"));
            statement.setString(2, (String)((Map<String,Object>) inputMap.get("body-json")).get("numberToRetrieve"));
            ResultSet messageResult = statement.executeQuery();

            // Processing results
            ArrayList<Message> messages = new ArrayList<>();
            while (messageResult.next()) {
                String content = messageResult.getString(1);
                String messageId = messageResult.getString(2);
                long timeSent = messageResult.getTimestamp(3).toInstant().getEpochSecond();
                String sender = messageResult.getString(4);

                if (timeSent >= 0) {
                    messages.add(new Message(content, messageId, timeSent, sender));
                }
            }

            // Disconnect connection with shortest lifespan possible
            connection.close();

            Message[] tempArray = new Message[messages.size()];
            GetMessagesResponse response = new GetMessagesResponse(messages.toArray(tempArray));

            return response;
        } catch (Exception e) {
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

    private class GetMessagesRequest {
        private String conversationId;
        private int nMessages;
        private int startIndex;
        private long sinceWhen;

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

    private class Message {
        private String content;
        private String messageID;
        private long timeSent;
        private String sender;

        public Message(String content, String messageId, long timeSent, String sender) {
            this.content = content;
            this.messageID = messageId;
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
            return messageID;
        }

        public void setMessageId(String messageId) {
            this.messageID = messageId;
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
        private Message[] messageList;

        public GetMessagesResponse(Message[] messageList) {
            this.messageList = messageList;
        }

        public Message[] getMessages() {
            return messageList;
        }

        public void setMessages(Message[] messageList) {
            this.messageList = messageList;
        }
    }

    public static void main(String[] args) {
        throw new IllegalStateException();
    }
}
