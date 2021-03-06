package DoctorsNote;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;

import java.sql.SQLException;
import java.util.Map;

/*
 * A Lambda handler for getting the most recent N messages in a given conversation.
 *
 * Expects: A JSON string that maps to a POJO of type GetOldMessagesRequest
 * Returns: A JSON string that maps from a POJO of type GetOldMessagesResponse
 *
 * Error Handling: Returns null if an unrecoverable error is encountered
 */
public class GetMessages implements RequestHandler<Map<String,Object>, MessageGetter.GetMessagesResponse> {

    public MessageGetter.GetMessagesResponse handleRequest(Map<String,Object> inputMap, Context context) {
        try {
            MessageGetter messageGetter = makeMessageGetter();
            MessageGetter.GetMessagesResponse response = messageGetter.get(inputMap, context);
            if (response == null) {
                System.out.println("GetMessages: MessageGetter returned null");
                throw new RuntimeException("Server experienced an error");
            }
            System.out.println("GetMessages: MessageGetter returned valid response");
            return response;
        } catch (SQLException e) {
            // This should only execute if closing the connection failed
            System.out.println("GetMessages: Could not close the database connection");
            return null;
        }
    }

    public MessageGetter makeMessageGetter() {
        System.out.println("GetMessages: Instantiating MessageGetter");
        return new MessageGetter(Connector.getConnection());
    }

    public static void main(String[] args) {
        System.out.println("GetMessages: Executing main() (THIS SHOULD NEVER HAPPEN)");
        throw new IllegalStateException();
    }
}
