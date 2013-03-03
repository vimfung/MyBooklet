package cn.vimfung.mybooklet.framework.module.myposts.notification
{
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.observer.Notification;
	
	/**
	 * 文章通知 
	 * @author Administrator
	 * 
	 */	
	public class PostNotification extends Notification implements INotification
	{
		public function PostNotification(name:String, body:Object=null, type:String=null)
		{
			super(name, body, type);
		}
		
		/**
		 * 开始刷新列表 
		 */		
		public static const BEGIN_REFRESH_LIST:String = "beginRefreshList";
		
		/**
		 * 更新文章 
		 */		
		public static const UPDATE_POST:String = "updatePost";
		
		/**
		 * 添加文章 
		 */		
		public static const ADD_POST:String = "addPost";
		
		/**
		 * 删除文章 
		 */		
		public static const DELETE_POST:String = "deletePost";
		
		/**
		 * 开始导入网络文章 
		 */		
		public static const BEGIN_IMPORT_URL_POST:String = "beginImportUrlPost";
		
		/**
		 * 导入网络文章加载进度 
		 */		
		public static const IMPORT_URL_POST_LOAD_PROGRESS:String = "importUrlPostLoadProgress";
		
		/**
		 * 导入网络文章加载成功 
		 */		
		public static const IMPORT_URL_POST_LOAD_SUCCESS:String = "importUrlPostLoadSuccess";
		
		/**
		 * 导入网络文章加载失败 
		 */		
		public static const IMPORT_URL_POST_LOAD_ERROR:String = "importUrlPostLoadError";
	}
}