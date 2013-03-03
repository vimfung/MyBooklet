package cn.vimfung.mybooklet.framework.patch
{
	import cn.vimfung.gnotes.kit.ISystemManager;
	
	import flash.events.IEventDispatcher;

	/**
	 * 补丁对象接口 
	 * @author Administrator
	 * 
	 */	
	public interface IPatchObject extends IEventDispatcher
	{
		/**
		 * 开始执行补丁 
		 * @param system 系统管理器
		 * 
		 */		
		function start(system:ISystemManager):void;
	}
}