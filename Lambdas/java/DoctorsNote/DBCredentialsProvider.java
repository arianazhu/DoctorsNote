package DoctorsNote;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;

/*
 * A generic, non-instantiable class for getting authentication
 * values from DBCredentials.tsv in a scalable, maintainable way.
 *
 * This class should not be instantiated more than once per
 * execution path. (It is permitted to do so, but is redundant
 * and adds unnecessary overhead)
 */
public class DBCredentialsProvider {
    private String tsvFilePath;
    private final String delimeter = ";;;;";

    private final String DBProvider;
    private final String DBEndpoint;
    private final String DBPort;
    private final String DBUrl;
    private final String DBUsername;
    private final String DBPassword;
    private final String DBName;
    private final String DBDriver;

    public DBCredentialsProvider(String tsvFilePath) throws IOException {
        try {
            this.tsvFilePath = tsvFilePath;
            System.out.println("DBCredentialsProvider: Attempting to access DBCredentials.tsv");
            BufferedReader br = new BufferedReader(new FileReader(tsvFilePath));
            System.out.println("DBCredentialsProvider: Access attempt successful");

            DBProvider = br.readLine().split(delimeter)[1];
            DBEndpoint = br.readLine().split(delimeter)[1];
            DBPort = br.readLine().split(delimeter)[1];
            DBUsername = br.readLine().split(delimeter)[1];
            DBPassword = br.readLine().split(delimeter)[1];
            DBName = br.readLine().split(delimeter)[1];
            DBDriver = br.readLine().split(delimeter)[1];

            br.close();

            DBUrl = DBProvider + DBEndpoint + ":" + DBPort + "/" + DBName;
        }
        catch(IOException e){
            System.out.println("DBCredentialsProvider: Instantiation failed");
            throw new IOException("Unable to read DBCredentials.tsv");
        } finally {
            System.out.println("DBCredentialsProvider: Instantiation successful");
        }
    }

    public DBCredentialsProvider() throws IOException {
        this("DBCredentials.tsv");
    }

    public String getDBProvider() {
        return this.DBProvider;
    }

    public String getDBEndpoint() {
        return this.DBEndpoint;
    }

    public String getDBPort() {
        return this.DBPort;
    }

    public String getDBURL() {
        return this.DBUrl;
    }

    public String getDBUsername() {
        return this.DBUsername;
    }

    public String getDBPassword() {
        return this.DBPassword;
    }

    public String getDBName() {
        return this.DBName;
    }

    public String getDBDriver() {
        return this.DBDriver;
    }

    public String getTsvFilePath() { return this.tsvFilePath; }

    public void setTsvFilePath(String path) { this.tsvFilePath = path; }
}
