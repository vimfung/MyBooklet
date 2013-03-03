package cn.vimfung.mybooklet.framework.module.myposts.events
{
	import cn.vimfung.mybooklet.framework.model.ProgressInfo;
	
	import flash.events.Event;
	
	/**
	 * 文章事件 
	 * @author Administrator
	 * 
	 */	
	public class PostEvent extends Event
	{
		public function PostEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		/**
		 * 获取文章返回 
		 */		
		public static const GET_POST_RESULT:String = "getPostResult";
		
		/**
		 * 获取文章错误 
		 */		
		public static const GET_POST_ERROR:String = "getPostError";
		
		/**
		 * 获取文章列表返回 
		 */		
		public static const GET_POSTS_RESULT:String = "getPostsResult";
		
		/**
		 * 获取文章列表错误 
		 */		
		public static const GET_POSTS_ERROR:String = "getPostsError";
		
		/**
		 * 创建文章返回 
		 */		
		public static const CREATE_POST_RESULT:String = "createPostResult";
		
		/**
		 * 创建文章失败 
		 */		
		public static const CREATE_POST_ERROR:String = "createPostError";
		
		/**
		 * 创建文章进度 
		 */		
		public static const CREATE_POST_PROGRESS:String = "createPostProgress";
		
		/**
		 * 更新文章返回 
		 */		
		public static const UPDATE_POST_RESULT:String = "updatePostResult";
		
		/**
		 * 更新文章失败 
		 */		
		public static const UPDATE_POST_ERROR:String = "updatePostError";
		
		/**
		 * 更新文章进度 
		 */		
		public static const UPDATE_POST_PROGRESS:String = "updatePostProgress";
		
		/**
		 * 删除文章返回 
		 */		
		public static const REMOVE_POST_RESULT:String = "removePostResult";
		
		/**
		 * 删除文章失败 
		 */		
		public static const REMOVE_POST_ERROR:String = "removePostError";
		
		/**
		 * 获取常用标签列表返回
		 */		
		public static const GET_USED_TAGS_RESULT:String = "getUsedTagsResult";
		
		/**
		 * 获取标签列表失败 
		 */		
		public static const GET_TAGS_ERROR:String = "getTagsError";
		
		/**
		 * 获取标签列表返回
		 */		
		public static const GET_TAGS_RESULT:String = "getTagsResult";
		
		/**
		 * 获取常用标签列表失败 
		 */		
		public static const GET_USED_TAGS_ERROR:String = "getUsedTagsError";
		
		/**
		 * 导出返回 
		 */		
		public static const EXPORT_RESULT:String = "exportResult";
		
		/**
		 * 导出失败 
		 */		
		public static const EXPORT_ERROR:String = "exportError";
		
		/**
		 * 标记颜色返回 
		 */		
		public static const MASK_COLOR_RESULT:String = "maskColorResult";
		
		/**
		 * 标记颜色失败 
		 */		
		public static const MASK_COLOR_ERROR:String = "maskColorError";
		
		private var _error:Error;
		private var _postInfo:Object;
		private var _attachments:Array;
		private var _progressInfo:ProgressInfo;
		private var _tags:Array;
		private var _posts:Array;
		private var _tag:Object;
		private var _pageNo:int;
		
		/**
		 * 获取页码 
		 * @return 页码
		 * 
		 */		
		public function get pageNo():int
		{
			return _pageNo;
		}

		/**
		 * 设置页码 
		 * @param value 页码
		 * 
		 */		
		public function set pageNo(value:int):void
		{
			_pageNo = value;
		}

		/**
		 * 获取标签信息 
		 * @return 标签信息
		 * 
		 */		
		public function get tag():Object
		{
			return _tag;
		}

		/**
		 * 设置标签信息 
		 * @param value 标签信息
		 * 
		 */		
		public function set tag(value:Object):void
		{
			_tag = value;
		}

		/**
		 * 获取文章列表 
		 * @return 文章列表
		 * 
		 */		
		public function get posts():Array
		{
			return _posts;
		}

		/**
		 * 设置文章列表 
		 * @param value 文章列表
		 * 
		 */		
		public function set posts(value:Array):void
		{
			_posts = value;
		}

		/**
		 * 获取标签列表 
		 * @return 标签列表
		 * 
		 */		
		public function get tags():Array
		{
			return _tags;
		}

		/**
		 * 设置标签列表 
		 * @param value 标签列表
		 * 
		 */		
		public function set tags(value:Array):void
		{
			_tags = value;
		}

		/**
		 * 获取进度信息 
		 * @return 进度信息
		 * 
		 */		
		public function get progressInfo():ProgressInfo
		{
			return _progressInfo;
		}

		/**
		 * 设置进度信息 
		 * @param value 进度信息
		 * 
		 */		
		public function set progressInfo(value:ProgressInfo):void
		{
			_progressInfo = value;
		}

		/**
		 * 获取附件列表 
		 * @return 附件列表
		 * 
		 */		
		public function get attachments():Array
		{
			return _attachments;
		}

		/**
		 * 设置附件列表 
		 * @param value 附件列表
		 * 
		 */		
		public function set attachments(value:Array):void
		{
			_attachments = value;
		}

		/**
		 * 获取文章信息 
		 * @return 文章信息
		 * 
		 */		
		public function get postInfo():Object
		{
			return _postInfo;
		}

		/**
		 * 设置文章信息 
		 * @param value 文章信息
		 * 
		 */		
		public function set postInfo(value:Object):void
		{
			_postInfo = value;
		}

		/**
		 * 获取错误信息 
		 * @return 错误信息
		 * 
		 */		
		public function get error():Error
		{
			return _error;
		}

		/**
		 * 设置错误信息 
		 * @param value 错误信息
		 * 
		 */		
		public function set error(value:Error):void
		{
			_error = value;
		}

	}
}