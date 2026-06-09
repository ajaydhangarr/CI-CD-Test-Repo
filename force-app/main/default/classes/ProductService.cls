public with sharing class ProductService {
  public static List<Product__c> getProducts() {
    return [
      SELECT Id, Name, Price__c, Quantity__c, Category__c, InStock__c
      FROM Product__c
      WITH USER_MODE
    ];
  }

  public static Product__c getProductById(Id productId) {
    if (productId == null) {
      return null;
    }
    List<Product__c> products = [
      SELECT Id, Name, Price__c, Quantity__c, Category__c, InStock__c
      FROM Product__c
      WHERE Id = :productId
      WITH USER_MODE
      LIMIT 1
    ];
    return products.isEmpty() ? null : products[0];
  }

  public static Product__c createProduct(
    String name,
    Decimal price,
    Integer quantity,
    String category,
    Boolean inStock
  ) {
    Product__c newProduct = new Product__c(
      Name = name,
      Price__c = price,
      Quantity__c = quantity,
      Category__c = category,
      InStock__c = inStock
    );
    insert newProduct;
    return newProduct;
  }

  public static Product__c updateProduct(Product__c product) {
    if (product == null || product.Id == null) {
      throw new IllegalArgumentException('Product record or ID cannot be null');
    }
    update product;
    return product;
  }

  public static void deleteProduct(Id productId) {
    if (productId == null) {
      throw new IllegalArgumentException('Product ID cannot be null');
    }
    Product__c toDelete = new Product__c(Id = productId);
    delete toDelete;
  }
}
