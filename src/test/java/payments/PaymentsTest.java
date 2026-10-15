package payments;

import io.karatelabs.core.Runner;
import io.karatelabs.core.SuiteResult;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertTrue;

public class PaymentsTest {

    // mvn test -Dkarate.env=test -DcustomerId=<DNI con deuda> [-Dtags=@bcp] [-DdryRun=true]
    // Equivale a los perfiles de cucumber.cjs de los repos -qa: los tags eligen qué se ejecuta.
    @Test
    void ejecutarFeatures() {
        SuiteResult result = Runner.path("classpath:features")
            .tags(System.getProperty("tags", "@regression"))
            .dryRun(Boolean.getBoolean("dryRun"))
            .outputHtmlReport(true)
            .outputJunitXml(true)
            .outputCucumberJson(true)
            .parallel(1);
        assertTrue(result.isPassed());
    }
}
