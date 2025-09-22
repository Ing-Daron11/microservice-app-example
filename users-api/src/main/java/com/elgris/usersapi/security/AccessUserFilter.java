package com.elgris.usersapi.security;

import io.jsonwebtoken.Claims;
import org.springframework.web.filter.GenericFilterBean;

import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import java.io.IOException;

public class AccessUserFilter extends GenericFilterBean {

    @Override
    public void doFilter(final ServletRequest req, final ServletResponse res, final FilterChain chain)
            throws IOException, ServletException {
        
        final HttpServletRequest request = (HttpServletRequest) req;
        final Claims claims = (Claims) request.getAttribute("claims");
        

        
        chain.doFilter(req, res);
    }
}