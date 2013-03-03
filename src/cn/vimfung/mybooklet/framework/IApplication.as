package cn.vimfung.mybooklet.framework
{
	import cn.vimfung.mybooklet.framework.model.Module;
	import cn.vimfung.mybooklet.framework.ui.NavigationBar;
	
	import spark.modules.ModuleLoader;

	/**
	 * 应用程序接口 
	 * @author Administrator
	 * 
	 */	
	public interface IApplication
	{
		/**
		 * 获取导航栏 
		 * @return 导航栏
		 * 
		 */		
		function get navigationBar():NavigationBar;
		
		/**
		 * 获取内容视图 
		 * @return 内容视图
		 * 
		 */		
		function get contentView():ModuleLoader;
	}
}