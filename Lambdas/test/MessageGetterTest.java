import DoctorsNote.MessageGetter;
import com.amazonaws.services.lambda.runtime.Context;
import org.junit.Before;
import org.junit.Test;
import org.junit.Assert;
import org.mockito.Mockito;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;

public class MessageGetterTest {
    Connection connectionMock;
    Context contextMock;

    @Before
    public void beforeTests() {
        connectionMock = Mockito.mock(Connection.class);
        contextMock = Mockito.mock(Context.class);
    }

    private HashMap getSampleMap() {
        HashMap<String, HashMap> topMap = new HashMap();
        HashMap<String, Object> jsonBody = new HashMap();
        jsonBody.put("conversationID", "0000000001");
        jsonBody.put("numberToRetrieve", "20");
        topMap.put("body-json", jsonBody);
        HashMap<String, Object> context = new HashMap();
        context.put("sub", "fake-user");
        topMap.put("context", context);
        return topMap;
    }

    @Test()
    public void testEmptyInputs() throws SQLException {
        MessageGetter messageGetter = new MessageGetter(connectionMock);
        Assert.assertEquals(null, messageGetter.get(new HashMap<>(), contextMock));
    }

    @Test()
    public void testMissingInput() throws SQLException {
        HashMap incompleteMap = getSampleMap();
        ((HashMap) incompleteMap.get("body-json")).remove("context");
        MessageGetter messageGetter = new MessageGetter(connectionMock);
        Assert.assertEquals(null, messageGetter.get(incompleteMap, contextMock));
    }

    @Test()
    public void testBadInput() throws SQLException {
        HashMap incompleteMap = getSampleMap();
        ((HashMap) incompleteMap.get("context")).put("sub", 1);
        MessageGetter messageGetter = new MessageGetter(connectionMock);
        Assert.assertEquals(null, messageGetter.get(incompleteMap, contextMock));
    }

    @Test()
    public void testConnectionError() throws SQLException {
        HashMap incompleteMap = getSampleMap();
        MessageGetter messageGetter = new MessageGetter(connectionMock);
        try {
            PreparedStatement statementMock = Mockito.mock(PreparedStatement.class);
            Mockito.when(statementMock.executeUpdate()).thenThrow(new RuntimeException());
            Mockito.when(connectionMock.prepareStatement(Mockito.anyString())).thenReturn(statementMock);
        } catch (SQLException e) {
            Assert.fail();
        }
        Assert.assertEquals(null, messageGetter.get(incompleteMap, contextMock));
    }

    @Test()
    public void testCompleteInput() throws SQLException {
        HashMap completeMap = getSampleMap();
        try {
            // Mocking necessary connection elements
            PreparedStatement psMock = Mockito.mock(PreparedStatement.class);
            ResultSet rsMock = Mockito.mock(ResultSet.class);
            Mockito.when(connectionMock.prepareStatement(Mockito.anyString())).thenReturn(psMock);
            Mockito.when(psMock.executeQuery()).thenReturn(rsMock);
            Mockito.when(rsMock.next()).thenReturn(false);
        } catch (SQLException e) {
            Assert.fail();
        }
        MessageGetter messageGetter = new MessageGetter(connectionMock);
        Assert.assertNotNull(messageGetter.get(completeMap, contextMock));
    }
}
