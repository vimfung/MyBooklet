package cn.vimfung.mybooklet.framework.module.myposts
{
	import cn.vimfung.mybooklet.framework.GNFacade;
	
	import flash.filesystem.File;
	
	import mx.controls.Alert;

	/**
	 * 我的文章常量 
	 * @author Administrator
	 * 
	 */	
	public class Constant extends Object
	{
		public function Constant()
		{
			super();
		}
		
		/**
		 * 获取文档路径 
		 * @return 文档路径
		 * 
		 */		
		public static function get DocumentPath():File
		{
			var file:File = null;
			try
			{
				file = File.documentsDirectory.resolvePath("GNotes");
			}
			catch(e:Error)
			{
				switch(e.errorID)
				{
					case 2014:
						GNFacade.getInstance().alert("发现异常!您的文档目录指向可能存在问题，请通过右键\"我的文档\"，查看\"属性\"-->\"位置\"来查看并修改为正确的文档目标指向。");
						break;
					default:
						GNFacade.getInstance().alert("发现异常!" + e.message);
						break;
				}
				throw e;
			}
			
			if(!file.exists)
			{
				file.createDirectory();
			}
			return file;
		}
		
		/**
		 * 获取数据文件路径
		 * @return 数据库文件路径
		 * 
		 */		
		public static function get DatabaseFile():File
		{
			return Constant.DocumentPath.resolvePath("note.db");
		}
		
		/**
		 * 获取存放附件目录 
		 * @return 附件目录
		 * 
		 */		
		public static function get AttachmentPath():File
		{
			var file:File = Constant.DocumentPath.resolvePath("attach");
			if(!file.exists)
			{
				file.createDirectory();
			}
			
			return file;
		}
		
		/**
		 * 获取存放内容引用文件目录 
		 * @return 内容引用文件目录
		 * 
		 */		
		public static function get FilesPath():File
		{
			var file:File = Constant.DocumentPath.resolvePath("files");
			if (!file.exists)
			{
				file.createDirectory();
			}
			
			return file;
		}
	}
}