package financiera.bcp;

import io.karatelabs.core.Runner;
import io.karatelabs.core.SuiteResult;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertTrue;

public class BcpFinancialApiTest {

    @Test
    void ejecutarPruebasBcpPorTag() {
        SuiteResult result = Runner.path("classpath:financiera/bcp")
            .tags(selectedTag())
            .outputHtmlReport(true)
            .parallel(1);
        assertTrue(result.isPassed());
    }

    private static String selectedTag() {
        String options = System.getProperty("karate.options", "");
        java.util.regex.Matcher matcher = java.util.regex.Pattern
            .compile("--tags\\s+([^\\s]+)")
            .matcher(options);
        return matcher.find() ? matcher.group(1) : "@regression";
    }
}
