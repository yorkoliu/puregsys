### 一、开发平台 ###
  * Django
  * mysql5.0+

### 二、功能介绍 ###
> 平台使用Django+mysql开发，支持POS/GET两种模式，POST方式用于管理员的手工推送，GET方式则用于接口模式。平台将接收到的URL进行校验、分类后统一向所属缓存服务器组进行telnet pureg请求。遍历完所有主机后返回结果串。

### 三、系统架构图 ###
> <img src='http://blog.liuts.com/attachment/201010/1287215944_56725166.png'><br></li></ul>

### 四、平台截图 ###
  * 管理UI
> > <img src='http://blog.liuts.com/attachment/201010/1287152458_1760351a.png'><br>
</li></ul>  * 接口说明
> > <img src='http://blog.liuts.com/attachment/201010/1287157746_26000b73.png'><br>
<br>
<h3>五、平台部署</h3>
</li></ul><ul><li><a href='http://blog.liuts.com/post/186/'>Centos5.4+Nginx-0.8.50+UWSGI-0.9.6.2+Django-1.2.3搭建高性能WEB服务器[原创]</a><br>
</li><li><a href='http://blog.liuts.com/post/217/'>构建高性能缓存推送平台[原创]</a><br></li></ul>

BLOG：<a href='http://blog.liuts.com'><a href='http://blog.liuts.com'>http://blog.liuts.com</a></a><br>
微博：<a href='http://t.qq.com/yorkoliu'><a href='http://t.qq.com/yorkoliu'>http://t.qq.com/yorkoliu</a></a><br>
交流QQ群：158926355