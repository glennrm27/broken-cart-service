package com.demo.cart.service;

import com.demo.cart.model.CartItem;
import com.demo.cart.model.CartTotal;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class CartService {

    private static final int COUPON_DISCOUNT_PERCENT = 15;

    public CartTotal calculateTotal(List<CartItem> items, String couponCode) {

        double subtotal = items.stream()
                .mapToDouble(item -> item.getPrice() * item.getQuantity())
                .sum();

        int discountPercent = (couponCode != null && !couponCode.isBlank())
                ? COUPON_DISCOUNT_PERCENT
                : 0;

        // BUG: integer division - discountPercent / 100 always evaluates to 0
        double discount = subtotal * (discountPercent / 100);

        double total = subtotal - discount;

        return new CartTotal(round(subtotal), round(discount), round(total));
    }

    private double round(double value) {
        return Math.round(value * 100.0) / 100.0;
    }
}