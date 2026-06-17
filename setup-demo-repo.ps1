# ============================================================
# Broken Cart Service - Demo Repository Setup Script
# PowerShell version for Windows - Plain text, no emojis
# Run from inside your cloned empty GitHub repo folder
# ============================================================

Write-Host "Setting up Broken Cart Service demo repository..." -ForegroundColor Cyan

# ------------------------------------------------------------
# Create directory structure
# ------------------------------------------------------------
Write-Host "Creating directory structure..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path ".github\workflows" | Out-Null
New-Item -ItemType Directory -Force -Path "src\main\java\com\demo\cart\service" | Out-Null
New-Item -ItemType Directory -Force -Path "src\main\java\com\demo\cart\model" | Out-Null
New-Item -ItemType Directory -Force -Path "src\test\java\com\demo\cart" | Out-Null

# ------------------------------------------------------------
# pom.xml
# ------------------------------------------------------------
Write-Host "Creating pom.xml..." -ForegroundColor Yellow
@'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.5</version>
    </parent>

    <groupId>com.demo</groupId>
    <artifactId>cart-service</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>cart-service</name>
    <description>Demo cart service for Agentic DevOps training</description>

    <properties>
        <java.version>17</java.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
'@ | Set-Content -Path "pom.xml" -Encoding UTF8

# ------------------------------------------------------------
# CartApplication.java
# ------------------------------------------------------------
Write-Host "Creating CartApplication.java..." -ForegroundColor Yellow
@'
package com.demo.cart;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class CartApplication {
    public static void main(String[] args) {
        SpringApplication.run(CartApplication.class, args);
    }
}
'@ | Set-Content -Path "src\main\java\com\demo\cart\CartApplication.java" -Encoding UTF8

# ------------------------------------------------------------
# CartItem.java
# ------------------------------------------------------------
Write-Host "Creating CartItem.java..." -ForegroundColor Yellow
@'
package com.demo.cart.model;

public class CartItem {

    private String name;
    private double price;
    private int quantity;

    public CartItem(String name, double price, int quantity) {
        this.name = name;
        this.price = price;
        this.quantity = quantity;
    }

    public String getName()  { return name; }
    public double getPrice() { return price; }
    public int getQuantity() { return quantity; }
}
'@ | Set-Content -Path "src\main\java\com\demo\cart\model\CartItem.java" -Encoding UTF8

# ------------------------------------------------------------
# CartTotal.java
# ------------------------------------------------------------
Write-Host "Creating CartTotal.java..." -ForegroundColor Yellow
@'
package com.demo.cart.model;

public class CartTotal {

    private final double subtotal;
    private final double discount;
    private final double total;

    public CartTotal(double subtotal, double discount, double total) {
        this.subtotal = subtotal;
        this.discount = discount;
        this.total    = total;
    }

    public double getSubtotal() { return subtotal; }
    public double getDiscount() { return discount; }
    public double getTotal()    { return total; }
}
'@ | Set-Content -Path "src\main\java\com\demo\cart\model\CartTotal.java" -Encoding UTF8

# ------------------------------------------------------------
# CartService.java - contains the bug
# ------------------------------------------------------------
Write-Host "Creating CartService.java (with the bug)..." -ForegroundColor Yellow
@'
package com.demo.cart.service;

import com.demo.cart.model.CartItem;
import com.demo.cart.model.CartTotal;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Calculates cart totals including promotional discounts.
 *
 * Conventions:
 * - Pure business logic only - no HTTP concerns
 * - All monetary values as double, rounded to 2dp at return boundary
 * - Discount logic centralised here, not in controller
 */
@Service
public class CartService {

    private static final int COUPON_DISCOUNT_PERCENT = 15;

    /**
     * Calculates the total for a cart, applying a percentage
     * discount if a coupon code is provided.
     *
     * @param items      list of items in the cart
     * @param couponCode optional coupon code; null means no discount
     * @return CartTotal containing subtotal, discount, and final total
     */
    public CartTotal calculateTotal(List<CartItem> items, String couponCode) {

        double subtotal = items.stream()
                .mapToDouble(item -> item.getPrice() * item.getQuantity())
                .sum();

        int discountPercent = (couponCode != null && !couponCode.isBlank())
                ? COUPON_DISCOUNT_PERCENT
                : 0;

        // BUG: integer division - discountPercent / 100 always evaluates
        // to 0 because both operands are int. Discount is never applied.
        double discount = subtotal * (discountPercent / 100);

        double total = subtotal - discount;

        return new CartTotal(
                round(subtotal),
                round(discount),
                round(total)
        );
    }

    private double round(double value) {
        return Math.round(value * 100.0) / 100.0;
    }
}
'@ | Set-Content -Path "src\main\java\com\demo\cart\service\CartService.java" -Encoding UTF8

# ------------------------------------------------------------
# CartServiceTest.java
# ------------------------------------------------------------
Write-Host "Creating CartServiceTest.java..." -ForegroundColor Yellow
@'
package com.demo.cart;

import com.demo.cart.model.CartItem;
import com.demo.cart.model.CartTotal;
import com.demo.cart.service.CartService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

class CartServiceTest {

    private CartService cartService;

    @BeforeEach
    void setUp() {
        cartService = new CartService();
    }

    @Test
    @DisplayName("No coupon - full price charged")
    void testNoCoupon() {
        List<CartItem> items = List.of(
                new CartItem("Widget", 100.0, 1)
        );

        CartTotal result = cartService.calculateTotal(items, null);

        assertEquals(100.0, result.getSubtotal(), "Subtotal should be 100.0");
        assertEquals(0.0,   result.getDiscount(), "Discount should be 0");
        assertEquals(100.0, result.getTotal(),    "Total should be 100.0");
    }

    @Test
    @DisplayName("Valid coupon - 15 percent discount applied correctly")
    void testCouponAppliesDiscount() {
        List<CartItem> items = List.of(
                new CartItem("Widget", 100.0, 1)
        );

        CartTotal result = cartService.calculateTotal(items, "SAVE15");

        assertEquals(100.0, result.getSubtotal(), "Subtotal should be 100.0");
        assertEquals(15.0,  result.getDiscount(), "Discount should be 15.0");
        assertEquals(85.0,  result.getTotal(),    "Total should be 85.0");
    }

    @Test
    @DisplayName("Multiple items with coupon - discount on full subtotal")
    void testMultipleItemsWithCoupon() {
        List<CartItem> items = List.of(
                new CartItem("Widget", 50.0, 2),
                new CartItem("Gadget", 30.0, 1)
        );

        CartTotal result = cartService.calculateTotal(items, "SAVE15");

        assertEquals(130.0, result.getSubtotal());
        assertEquals(19.5,  result.getDiscount());
        assertEquals(110.5, result.getTotal());
    }

    @Test
    @DisplayName("Blank coupon treated as no discount")
    void testBlankCouponNoDiscount() {
        List<CartItem> items = List.of(
                new CartItem("Widget", 100.0, 1)
        );

        CartTotal result = cartService.calculateTotal(items, "");

        assertEquals(0.0,   result.getDiscount(), "Blank coupon should give no discount");
        assertEquals(100.0, result.getTotal());
    }
}
'@ | Set-Content -Path "src\test\java\com\demo\cart\CartServiceTest.java" -Encoding UTF8

# ------------------------------------------------------------
# CI workflow
# ------------------------------------------------------------
Write-Host "Creating CI workflow..." -ForegroundColor Yellow
@'
name: CI - Build and Test

on:
  push:
    branches: [ "**" ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-test:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Java 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
          cache: maven

      - name: Build and run tests
        run: mvn test

      - name: Publish test results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results
          path: target/surefire-reports/
'@ | Set-Content -Path ".github\workflows\ci.yml" -Encoding UTF8

# ------------------------------------------------------------
# Copilot instructions
# ------------------------------------------------------------
Write-Host "Creating copilot-instructions.md..." -ForegroundColor Yellow
@'
# Copilot Instructions - broken-cart-service

## Before generating any code
1. Use @workspace to inspect existing package structure
2. Read CONVENTIONS.md before making any changes
3. Do not introduce new dependencies
4. Do not create new classes if an existing one can be extended

## Package conventions
- Service classes in `com.demo.cart.service`
- Models in `com.demo.cart.model`
- Tests mirror the main package structure under `src/test`

## Code conventions
- Constructor injection only - no @Autowired on fields
- All monetary rounding via the private `round()` method in CartService
- Javadoc required on all public methods
- Test method names follow: `testWhatScenarioExpectedResult` pattern

## Testing conventions
- JUnit 5 only
- @DisplayName on every test
- One assertion concept per test
- Tests must not depend on each other

## What NOT to do
- Do not add logging frameworks - none are configured
- Do not add a database or persistence layer
- Do not modify pom.xml without flagging in PR description
- Do not remove existing test cases - only add new ones
'@ | Set-Content -Path ".github\copilot-instructions.md" -Encoding UTF8

# ------------------------------------------------------------
# CONVENTIONS.md
# ------------------------------------------------------------
Write-Host "Creating CONVENTIONS.md..." -ForegroundColor Yellow
@'
# Repository Conventions

## Purpose
This is a training repository used to demonstrate Agentic DevOps
workflows with GitHub Copilot. It intentionally contains a bug
for demonstration purposes.

## Architecture
Single Spring Boot service with no external dependencies.
Business logic lives entirely in CartService.

## The Known Bug
CartService.calculateTotal() contains an integer division error
that prevents discount codes from being applied correctly.
See CartServiceTest.testCouponAppliesDiscount for the failing test.

## What a correct fix looks like
- Change `discountPercent / 100` to `discountPercent / 100.0`
- All existing tests should pass after the fix
- No new dependencies, no structural changes required

## Coding Standards
- Java 17
- Spring Boot 3.2.x
- Maven
- JUnit 5 for tests
'@ | Set-Content -Path "CONVENTIONS.md" -Encoding UTF8

# ------------------------------------------------------------
# README.md
# ------------------------------------------------------------
Write-Host "Creating README.md..." -ForegroundColor Yellow
'@'
# Broken Cart Service

A deliberately buggy Spring Boot microservice used for
Agentic DevOps training demonstrations.

## The Scenario
The cart discount calculation contains a silent bug - valid
coupon codes are accepted but no discount is ever applied.
Customers are being charged full price.

## Run the tests to see the failure