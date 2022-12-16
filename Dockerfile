ARG version=1.22.1

FROM nginx:stable-alpine AS builder

ARG version
ARG pam=1.5.3
ARG header=0.34
ARG fancyindex=0.5.2

WORKDIR /root/

# base nginx
RUN apk add --update --no-cache build-base pcre2-dev zlib-dev linux-pam-dev brotli-dev \
    && wget http://nginx.org/download/nginx-${version}.tar.gz \
    && tar zxf nginx-${version}.tar.gz \

    # auth-pam module
    && wget https://github.com/sto/ngx_http_auth_pam_module/archive/refs/tags/v${pam}.tar.gz -O ngx_auth.tar.gz \
    && tar xf ngx_auth.tar.gz \
    && cd ngx_http_auth_pam_module-${pam} \
    && cd ../nginx-${version} \
    && ./configure --with-compat --add-dynamic-module=../ngx_http_auth_pam_module-${pam} \
    && make modules \

    # brotli module
    && cd /root/ \
    && wget https://github.com/google/ngx_brotli/archive/refs/tags/v1.0.0rc.tar.gz -O ngx_brotli.tar.gz \
    && tar xf ngx_brotli.tar.gz \
    && cd ngx_brotli-1.0.0rc \
    && cd ../nginx-${version} \
    && ./configure --with-compat --add-dynamic-module=../ngx_brotli-1.0.0rc \
    && make modules \

    # header-more module
    && cd /root/ \
    && wget https://github.com/openresty/headers-more-nginx-module/archive/refs/tags/v${header}.tar.gz -O ngx_header.tar.gz \
    && tar xf ngx_header.tar.gz \
    && cd headers-more-nginx-module-${header} \
    && cd ../nginx-${version} \
    && ./configure --with-compat --add-dynamic-module=../headers-more-nginx-module-${header} \
    && make modules \

    # fancyindex module
    && cd /root/ \
    && wget https://github.com/aperezdc/ngx-fancyindex/archive/refs/tags/v${fancyindex}.tar.gz -O ngx_fancyindex.tar.gz \
    && tar xf ngx_fancyindex.tar.gz \
    && cd ngx-fancyindex-${fancyindex} \
    && cd ../nginx-${version} \
    && ./configure --with-compat --add-dynamic-module=../ngx-fancyindex-${fancyindex} \
    && make modules

FROM nginx:stable-alpine

ARG version
# copy all the modules
COPY --from=builder /root/nginx-${version}/objs/ngx_http_auth_pam_module.so /usr/lib/nginx/modules/
COPY --from=builder /root/nginx-${version}/objs/ngx_http_brotli_filter_module.so /usr/lib/nginx/modules/
COPY --from=builder /root/nginx-${version}/objs/ngx_http_brotli_static_module.so /usr/lib/nginx/modules/
COPY --from=builder /root/nginx-${version}/objs/ngx_http_headers_more_filter_module.so /usr/lib/nginx/modules/
COPY --from=builder /root/nginx-${version}/objs/ngx_http_fancyindex_module.so /usr/lib/nginx/modules/

# remove debug modules we don't need it
RUN rm /usr/lib/nginx/modules/*-debug.so