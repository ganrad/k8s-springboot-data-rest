package ocp.s2i.springboot.rest.model;

import java.util.List;

import org.springframework.data.repository.PagingAndSortingRepository;
import org.springframework.data.repository.query.Param;
import org.springframework.data.rest.core.annotation.RepositoryRestResource;

@RepositoryRestResource(collectionResourceRel = "orders", path = "orders")
public interface PORepository extends PagingAndSortingRepository<PurchaseOrder, Long> {

	List<PurchaseOrder> getByItem(@Param("item") String item);

}
