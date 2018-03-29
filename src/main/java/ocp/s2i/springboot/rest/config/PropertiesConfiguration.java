package ocp.s2i.springboot.rest.config;

// import java.util.List;
// import java.util.ArrayList;
// import org.springframework.beans.factory.config.PropertyPlaceholderConfigurer;
// import org.springframework.core.io.Resource;
// import org.springframework.core.io.FileSystemResource;
import org.springframework.context.annotation.*;
import org.springframework.context.support.PropertySourcesPlaceholderConfigurer;

@Configuration
@PropertySource("file:/etc/vol-secrets/username.properties")
@PropertySource("file:/etc/vol-secrets/password.properties")
@PropertySource("file:/etc/config/mysqldb.properties")
public class PropertiesConfiguration {


    /** @Bean
    public PropertyPlaceholderConfigurer properties() {
        final PropertyPlaceholderConfigurer ppc = new PropertyPlaceholderConfigurer();
//        ppc.setIgnoreUnresolvablePlaceholders(true);
        ppc.setIgnoreResourceNotFound(true);

        final List<Resource> resourceLst = new ArrayList<Resource>();

        // resourceLst.add(new ClassPathResource("myapp_base.properties"));
        resourceLst.add(new FileSystemResource("/etc/vol-secrets/username.properties"));
        resourceLst.add(new FileSystemResource("/etc/vol-secrets/password.properties"));
        // resourceLst.add(new ClassPathResource("myapp_test.properties"));
        // resourceLst.add(new ClassPathResource("myapp_developer_overrides.properties")); // for Developer debugging.

        ppc.setLocations(resourceLst.toArray(new Resource[]{}));

        return ppc;
    } */

    @Bean
    public static PropertySourcesPlaceholderConfigurer propertyConfig() {
	return new PropertySourcesPlaceholderConfigurer();
    }
}
