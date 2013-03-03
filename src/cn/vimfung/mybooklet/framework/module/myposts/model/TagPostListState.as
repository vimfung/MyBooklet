package cn.vimfung.mybooklet.framework.module.myposts.model
{
	import flash.utils.Dictionary;

	/**
	 * 标签文章列表状态 
	 * @author Administrator
	 * 
	 */	
	public class TagPostListState extends Object
	{
		public function TagPostListState()
		{
			super();
			_hasMoreTags = false;
			_tagPostsState = new Dictionary();
		}
		
		private var _hasMoreTags:Boolean;
		private var _pageNo:int;
		private var _tagPostsState:Dictionary;
		
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
		 * 获取标签文章列表状态 
		 * @return 标签文章列表状态
		 * 
		 */		
		public function get tagPostsState():Dictionary
		{
			return _tagPostsState;
		}

		/**
		 * 设置标签文章列表状态 
		 * @param value 标签文章列表状态
		 * 
		 */		
		public function set tagPostsState(value:Dictionary):void
		{
			_tagPostsState = value;
		}

		/**
		 * 获取是否有更多标签标识 
		 * @return 更多标签标识
		 * 
		 */		
		public function get hasMoreTags():Boolean
		{
			return _hasMoreTags;
		}

		/**
		 * 设置是否有更多标签标识 
		 * @param value 更多标签标识
		 * 
		 */		
		public function set hasMoreTags(value:Boolean):void
		{
			_hasMoreTags = value;
		}

	}
}