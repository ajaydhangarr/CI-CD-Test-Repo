@SuppressWarnings(
  'PMD.MethodNamingConventions, PMD.ApexAssertionsShouldIncludeMessage, PMD.ApexDoc'
)
@isTest(SeeAllData=false)
private class ProductServiceTest {
  @testSetup
  static void setupTestData() {
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    User testUser = new User(
      Username = 'testproductuser' + Math.random() + '@example.com',
      Alias = 'tpuser',
      Email = 'testproductuser@example.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Test',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      LocaleSidKey = 'en_US',
      LanguageLocaleKey = 'en_US'
    );
    insert testUser;

    PermissionSet ps = [
      SELECT Id
      FROM PermissionSet
      WHERE Name = 'Product_Manager_PS'
      LIMIT 1
    ];
    insert new PermissionSetAssignment(
      AssigneeId = testUser.Id,
      PermissionSetId = ps.Id
    );
  }

  @isTest
  static void testCreateProduct() {
    System.runAs([SELECT Id FROM User WHERE Alias = 'tpuser' LIMIT 1][0]) {
      Test.startTest();
      Product__c p = ProductService.createProduct(
        'Test Product',
        99.99,
        10,
        'Electronics',
        true
      );
      Test.stopTest();

      System.assertNotEquals(
        null,
        p.Id,
        'Product ID should not be null after creation'
      );
      Product__c retrieved = ProductService.getProductById(p.Id);
      System.assertEquals('Test Product', retrieved.Name, 'Name should match');
      System.assertEquals(99.99, retrieved.Price__c, 'Price should match');
      System.assertEquals(10, retrieved.Quantity__c, 'Quantity should match');
      System.assertEquals(
        'Electronics',
        retrieved.Category__c,
        'Category should match'
      );
      System.assertEquals(true, retrieved.InStock__c, 'InStock should be true');
    }
  }

  @isTest
  static void testGetProducts() {
    System.runAs([SELECT Id FROM User WHERE Alias = 'tpuser' LIMIT 1][0]) {
      ProductService.createProduct('Product A', 15.00, 50, 'Groceries', true);
      ProductService.createProduct('Product B', 45.00, 20, 'Fashion', true);

      Test.startTest();
      List<Product__c> products = ProductService.getProducts();
      Test.stopTest();

      System.assert(
        products.size() >= 2,
        'Should retrieve at least 2 products'
      );
    }
  }

  @isTest
  static void testGetProductById_NullId() {
    System.runAs([SELECT Id FROM User WHERE Alias = 'tpuser' LIMIT 1][0]) {
      Test.startTest();
      Product__c result = ProductService.getProductById(null);
      Test.stopTest();

      System.assertEquals(null, result, 'Null ID should return null');
    }
  }

  @isTest
  static void testUpdateProduct() {
    System.runAs([SELECT Id FROM User WHERE Alias = 'tpuser' LIMIT 1][0]) {
      Product__c p = ProductService.createProduct(
        'Original Product',
        10.00,
        5,
        'Home',
        true
      );
      p.Name = 'Updated Product';
      p.Price__c = 15.50;

      Test.startTest();
      ProductService.updateProduct(p);
      Test.stopTest();

      Product__c retrieved = ProductService.getProductById(p.Id);
      System.assertEquals(
        'Updated Product',
        retrieved.Name,
        'Name should have updated'
      );
      System.assertEquals(
        15.50,
        retrieved.Price__c,
        'Price should have updated'
      );
    }
  }

  @isTest
  static void testDeleteProduct() {
    System.runAs([SELECT Id FROM User WHERE Alias = 'tpuser' LIMIT 1][0]) {
      Product__c p = ProductService.createProduct(
        'Product to Delete',
        5.00,
        1,
        'Groceries',
        false
      );
      Id pId = p.Id;

      Test.startTest();
      ProductService.deleteProduct(pId);
      Test.stopTest();

      Product__c retrieved = ProductService.getProductById(pId);
      System.assertEquals(null, retrieved, 'Product should be deleted');
    }
  }

  @isTest
  static void testUpdateProduct_NullThrows() {
    System.runAs([SELECT Id FROM User WHERE Alias = 'tpuser' LIMIT 1][0]) {
      Test.startTest();
      try {
        ProductService.updateProduct(null);
        System.assert(false, 'Exception expected for null product');
      } catch (IllegalArgumentException e) {
        System.assertEquals(
          'Product record or ID cannot be null',
          e.getMessage()
        );
      }
      Test.stopTest();
    }
  }

  @isTest
  static void testUpdateProduct_NoIdThrows() {
    System.runAs([SELECT Id FROM User WHERE Alias = 'tpuser' LIMIT 1][0]) {
      Test.startTest();
      try {
        ProductService.updateProduct(new Product__c());
        System.assert(false, 'Exception expected for product with no ID');
      } catch (IllegalArgumentException e) {
        System.assertEquals(
          'Product record or ID cannot be null',
          e.getMessage()
        );
      }
      Test.stopTest();
    }
  }

  @isTest
  static void testDeleteProduct_NullThrows() {
    System.runAs([SELECT Id FROM User WHERE Alias = 'tpuser' LIMIT 1][0]) {
      Test.startTest();
      try {
        ProductService.deleteProduct(null);
        System.assert(false, 'Exception expected for null ID');
      } catch (IllegalArgumentException e) {
        System.assertEquals('Product ID cannot be null', e.getMessage());
      }
      Test.stopTest();
    }
  }
}
