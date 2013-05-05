package cn.vimfung.mybooklet.framework.events
{
	import cn.vimfung.common.db.SqliteDatabaseEvent;
	
	import flash.data.SQLSchemaResult;
	import flash.events.Event;
	
	/**
	 * Sqlite数据库事件 
	 * @author Administrator
	 * 
	 */	
	public class DBEvent extends SqliteDatabaseEvent
	{
		public function DBEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		/**
		 * 初始化数据库 
		 */		
		public static const INITIALIZE:String = "initialize";
	}
}