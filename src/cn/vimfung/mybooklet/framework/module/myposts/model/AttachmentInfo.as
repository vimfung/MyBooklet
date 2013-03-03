package cn.vimfung.mybooklet.framework.module.myposts.model
{
	import flash.filesystem.File;

	/**
	 * 附件信息 
	 * @author Administrator
	 * 
	 */	
	public class AttachmentInfo extends Object
	{
		public function AttachmentInfo(file:File)
		{
			super();
			
			_file = file;
		}
		
		/**
		 * 文件ID 
		 */		
		private var _id:Number;

		public function get id():Number
		{
			return _id;
		}
		
		public function set id(value:Number):void
		{
			_id = value;
		}
		
		/**
		 * 文件句柄 
		 */		
		private var _file:File;

		public function get file():File
		{
			return _file;
		}
		
		public function set file(value:File):void
		{
			_file = value;
		}
		
		/**
		 * 状态：0 等待上传，1 已上传 
		 */		
		private var _status:int;

		public function get status():int
		{
			return _status;
		}

		public function set status(value:int):void
		{
			_status = value;
		}
		
		/**
		 * 是否删除
		 * */
		private var _isDelete:Boolean;
		
		public function get isDelete():Boolean
		{
			return _isDelete;
		}
		
		public function set isDelete(value:Boolean):void
		{
			_isDelete = value;
		}
		
		private var _createTime:Date;
		
		/**
		 * 获取创建时间 
		 * @return 创建时间
		 * 
		 */		
		public function get createTime():Date
		{
			return _createTime;
		}
		
		/**
		 * 设置创建时间 
		 * @param value 创建时间
		 * 
		 */		
		public function set createTime(value:Date):void
		{
			_createTime = value;
		}
		
		/**
		 * 文件标题 
		 */		
		public function get title():String
		{
			return _file.name;
		}

	}
}