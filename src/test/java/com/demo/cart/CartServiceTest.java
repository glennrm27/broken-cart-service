package com.demo.cart;

import com.demo.cart.model.CartItem;
import com.demo.cart.model.CartTotal;
import com.demo.cart.service.CartService;
import org.junit.jupiter.api.BeforeEach;
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
    void testNoCoupon() {
        List<CartItem> items = List.of(new CartItem("Widget", 100.0, 1));
        CartTotal result = cartService.calculateTotal(items, null);
        assertEquals(100.0, result.getSubtotal());
        assertEquals(0.0,   result.getDiscount());
        assertEquals(100.0, result.getTotal());
    }

    @Test
    void testCouponAppliesDiscount() {
        List<CartItem> items = List.of(new CartItem("Widget", 100.0, 1));
        CartTotal result = cartService.calculateTotal(items, "SAVE15");
        assertEquals(100.0, result.getSubtotal());
        assertEquals(15.0,  result.getDiscount());
        assertEquals(85.0,  result.getTotal());
    }

    @Test
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
    void testBlankCouponNoDiscount() {
        List<CartItem> items = List.of(new CartItem("Widget", 100.0, 1));
        CartTotal result = cartService.calculateTotal(items, "");
        assertEquals(0.0,   result.getDiscount());
        assertEquals(100.0, result.getTotal());
    }
}