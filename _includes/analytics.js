var script = document.createElement('script');
script.src = 'https://www.googletagmanager.com/gtag/js?id={{ site.google_analytics }}';
script.async = true;
document.head.appendChild(script);

window.dataLayer = window.dataLayer || [];
function gtag(){dataLayer.push(arguments);}
gtag('js', new Date());
gtag('config', '{{ site.google_analytics }}');
