if (!!document.getElementById('disqus_thread')) {

    var disqus_config = function () {
        this.page.url = "{{ site.url }}{{ page.url }}";
        this.page.identifier = "{{ page.title }}";
    };

    (function() {
        var d = document, s = d.createElement('script');
        s.src = 'https://{{ site.disqus_shortname }}.disqus.com/embed.js';
        s.setAttribute('data-timestamp', +new Date());
        (d.head || d.body).appendChild(s);
    })();
}
