package cn.vimfung.mybooklet.framework.module.subscript
{
	import spark.components.List;

	/**
	 * 订阅接口 
	 * @author Administrator
	 * 
	 */	
	public interface ISubscript
	{
		/**
		 * 刷新当前订阅列表
		 * 
		 * @param result	返回事件回调
		 */		
		function refreshCurrentRssList(result:Function):void;
		
		/**
		 * 获取更多内容列表
		 * 
		 * @param item 最后一项数据，如果非最后一项则不会加载更多数据
		 */		
		function getMore(item:Object):void;
		
		/**
		 * 获取当前状态 
		 * @return 状态
		 * 
		 */		
		function get currentState():String;
		
		/**
		 * 设置当前状态 
		 * @param value 状态
		 * 
		 */		
		function set currentState(value:String):void;
	}
}