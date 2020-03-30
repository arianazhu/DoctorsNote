package DoctorsNote;

import com.amazonaws.services.lambda.runtime.Context;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.Timestamp;
import java.util.Map;

/*
 * Logic to process adding a reminder to the database.
 * NOTE: The passed connection will be closed
 */

public class ReminderAdder {
    private final String addReminderFormatString = "INSERT INTO Reminder (content, remindedID, creatorID, timeCreated, intradayFrequency, daysBetweenReminders, descriptionContent) VALUES (?, ?, ?, ?, ?, ?, ?);";
    Connection dbConnection;

    public ReminderAdder(Connection dbConnection) {
        this.dbConnection = dbConnection;
    }

    public ReminderAdder.AddReminderResponse add(Map<String, Object> inputMap, Context context) {
        try {
            System.out.println("ReminderAdder: Adding reminder on behalf of " + ((Map<String,Object>) inputMap.get("context")).get("sub"));
            PreparedStatement statement = dbConnection.prepareStatement(addReminderFormatString);
            statement.setString(1, (String)((Map<String,Object>) inputMap.get("body-json")).get("content"));
            statement.setString(2, (String)((Map<String,Object>) inputMap.get("body-json")).get("remindee"));
            statement.setString(3, (String)((Map<String,Object>) inputMap.get("context")).get("sub"));
            statement.setTimestamp(4, new Timestamp(Long.parseLong(((Map<String,Object>) inputMap.get("body-json")).get("timeCreated").toString())));
<<<<<<< HEAD
            statement.setTimestamp(5, new Timestamp(Long.parseLong(((Map<String,Object>) inputMap.get("body-json")).get("alertTime").toString())));
            System.out.println("ReminderAdder: statement: " + statement);
            int ret = statement.executeUpdate();

            if (ret == 0) {
                System.out.println("ReminderAdder: Update successful");
            } else {
                System.out.println(String.format("ReminderAdder: Update failed (%d)", ret));
            }
=======
            statement.setInt(5, Integer.parseInt(((Map<String,Object>) inputMap.get("body-json")).get("intradayFrequency").toString()));
            statement.setInt(6, Integer.parseInt(((Map<String,Object>) inputMap.get("body-json")).get("daysBetweenReminders").toString()));
            statement.setString(7, (String)((Map<String,Object>) inputMap.get("body-json")).get("descriptionContent"));
            System.out.println(statement);
            int res = statement.executeUpdate();
            System.out.println("Update executed with return code " + res);
>>>>>>> dev

            // Disconnect connection with shortest lifespan possible
            dbConnection.close();

            // Serialize and return an empty response object
            return new AddReminderResponse();
        } catch (Exception e) {
            System.out.println("ReminderAdder: Exception encountered: " + e.getMessage());
            return null;
        }
    }

    public class AddReminderResponse {
        // No payload necessary
    }
}
