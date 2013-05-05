package cn.vimfung.mybooklet.framework.module.myposts.proxy
{
	import cn.vimfung.common.db.SqliteDatabaseToken;
	import cn.vimfung.mybooklet.framework.GNFacade;
	import cn.vimfung.mybooklet.framework.module.myposts.PostToken;
	import cn.vimfung.mybooklet.framework.module.myposts.notification.PostNotification;
	import cn.vimfung.mybooklet.framework.module.myposts.token.CreatePostToken;
	import cn.vimfung.mybooklet.framework.module.myposts.token.UpdatePostToken;
	
	import flash.data.SQLResult;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import mx.utils.StringUtil;
	
	import org.puremvc.as3.interfaces.IProxy;
	import org.puremvc.as3.patterns.proxy.Proxy;
	
	/**
	 * 我的文章代理 
	 * @author Administrator
	 * 
	 */	
	public class MyPostsProxy extends Proxy implements IProxy
	{
		public static const NAME:String = "MyPostsProxy";
		
		public function MyPostsProxy()
		{
			super(MyPostsProxy.NAME, null);
			
			_gnFacade = this.facade as GNFacade;
		}
		
		private var _gnFacade:GNFacade;
		
		/**
		 * 获取最近文章列表 
		 * @param lastPost 上一页最后一篇文章记录，如果首页则传入null
		 * @param pageSize 分页大小
		 * @param keyword 关键字
		 * @param color 过滤颜色
		 * @return 文章请求令牌
		 * 
		 */		
		public function getLatestPosts(lastPost:Object = null, pageSize:Number = 10, keyword:String = null, color:uint = 0xffffff):PostToken
		{
			var token:PostToken = new PostToken();
			token.initGetLatestPostsToken(lastPost, pageSize, keyword, color);
			return token;
		}
		
		/**
		 * 获取标签ID 
		 * @param name 标签名称
		 * @return 标签ID
		 * 
		 */		
		public function getTagId(name:String):Number
		{
			var params:Dictionary = new Dictionary();
			params[":name"] = name;
			var token:SqliteDatabaseToken = _gnFacade.documentDatabase.createCommandToken("SELECT id FROM notes_tag WHERE name = :name", params);
			var data:Array = token.startSync().data;
			if (data != null && data.length >= 1)
			{
				return data[0].id;
			}
			
			return -1;
		}
		
		/**
		 * 根据标签获取文章列表 
		 * 
		 * @param 	tageInfo 	标签信息
		 * @param	lastPost	最后一条文章记录
		 * @param	pageSize	分页大小
		 * 
		 */		
		public function getPostsByTag(tagInfo:Object, lastPost:Object = null, pageSize:int = 30):PostToken
		{	
			var token:PostToken = new PostToken();
			token.initGetPostsWithTagToken(tagInfo, lastPost, pageSize);
			return token;
		}
		
		/**
		 * 获取文章信息 
		 * @param postId 文章ID
		 * @param keyword 关键字
		 * @return 令牌对象
		 * 
		 */		
		public function getPostInfo(postId:Number, keyword:String = null):PostToken
		{	
			var token:PostToken = new PostToken();
			token.initGetPostInfoToken(postId, keyword);
			return token;
		}
		
		/**
		 * 创建文章 
		 * @param title 标题
		 * @param content 内容
		 * @param tags 标签
		 * @param attachments 附件
		 * @param files 内容引用文件
		 * @return 令牌对象
		 * 
		 */		
		public function create(title:String, content:String, tags:String, attachments:Array, files:Array):CreatePostToken
		{
			return new CreatePostToken(title,content, tags, attachments, files);
		}
		
		/**
		 * 更新文章 
		 * @param postId 文章ID
		 * @param title	标题
		 * @param content	内容
		 * @param tags	标签
		 * @param attachments	附件列表
		 * @param files 引用文件列表
		 * @return 令牌对象
		 * 
		 */		
		public function update(postId:Number, title:String, content:String, tags:String, attachments:Array, files:Array):UpdatePostToken
		{
			return new UpdatePostToken(postId,title,content,tags,attachments,files);
		}
		
		/**
		 * 删除文章 
		 * @param post 文章信息
		 * @return 令牌对象
		 * 
		 */		
		public function remove(post:Object):PostToken
		{
			var token:PostToken = new PostToken();
			token.initRemovePostToken(post);
			return token;
		}
		
		/**
		 * 获取常用标签 
		 * @return 令牌对象
		 * 
		 */		
		public function getUsedTags():PostToken
		{
			var token:PostToken = new PostToken();
			token.initGetUsedTagsToken();
			return token;
		}
		
		/**
		 * 获取标签列表 
		 * @param pageNo 页码
		 * @return 令牌对象
		 * 
		 */		
		public function getTags(pageNo:Number):PostToken
		{
			var token:PostToken = new PostToken();
			token.initGetTagsToken(pageNo);
			return token;
		}
		
		/**
		 * 导出文章 
		 * @param filePath 导出文章路径
		 * @param type 导出类型
		 * @return 令牌对象
		 * 
		 */		
		public function export(postId:Number, filePath:String,type:int):PostToken
		{
			var token:PostToken = new PostToken();
			token.initExportPostToken(postId, filePath, type);
			return token;
		}
		
		/**
		 * 标记颜色 
		 * @param postId 文章ID
		 * @param color 颜色
		 * @return 令牌对象
		 * 
		 */		
		public function maskColor(postId:Number, color:uint):PostToken
		{
			var token:PostToken = new PostToken();
			token.initMaskPostColor(postId, color);
			return token;
		}
	}
}