package cn.vimfung.mybooklet.framework.module.myposts
{
	import cn.vimfung.mybooklet.framework.module.myposts.ui.PostContentView;
	import cn.vimfung.mybooklet.framework.module.myposts.ui.PostListView;
	
	import mx.controls.HTML;
	
	import spark.components.DataGrid;
	import spark.components.List;

	/**
	 * 我的文章模块接口 
	 * @author Administrator
	 * 
	 */	
	public interface IMyPosts
	{
		/**
		 * 获取文章列表视图 
		 * @return 文章列表视图
		 * 
		 */		
		function get postListView():PostListView;
		
		/**
		 * 获取内容视图 
		 * @return 内容视图
		 * 
		 */	
		function get contentView():PostContentView;
		
		/**
		 * 获取当前视图状态 
		 * @return 视图状态
		 * 
		 */		
		function get currentState():String;
		
		/**
		 * 设置当前视图状态 
		 * @param value 视图状态
		 * 
		 */		
		function set currentState(value:String):void;
	}
}