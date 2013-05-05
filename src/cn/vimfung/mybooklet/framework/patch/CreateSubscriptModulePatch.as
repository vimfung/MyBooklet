package cn.vimfung.mybooklet.framework.patch
{
	import cn.vimfung.common.db.SqliteDatabaseEvent;
	import cn.vimfung.common.db.SqliteDatabaseToken;
	import cn.vimfung.gnotes.kit.ISystemManager;
	import cn.vimfung.mybooklet.framework.GNFacade;
	import cn.vimfung.mybooklet.framework.events.PatchEvent;
	import cn.vimfung.mybooklet.framework.model.Module;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.Dictionary;
	
	import org.puremvc.as3.core.Model;
	
	/**
	 * 创建我的订阅模块
	 * @author Administrator
	 * 
	 * @since	ver1.4.0
	 */	
	public class CreateSubscriptModulePatch extends EventDispatcher implements IPatchObject
	{
		public static const NAME:String = "AF47A2D4AF187AE8";
		
		public function CreateSubscriptModulePatch(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		private var _subscriptModule:Module;
		private var _gnFacade:GNFacade;
		
		/**
		 * @inheritDoc
		 * 
		 */		
		public function start(system:ISystemManager):void
		{
			_gnFacade = GNFacade.getInstance();
			_subscriptModule = Module.getSubscriptModule();
			
			//写入系统模块:我的文章
			var parameters:Dictionary = new Dictionary();
			parameters[":id"] = _subscriptModule.id;
			var existsMyPostsToken:SqliteDatabaseToken = _gnFacade.systemDatabase.createCommandToken("SELECT id FROM sys_module WHERE id = :id", parameters);
			existsMyPostsToken.addEventListener(SqliteDatabaseEvent.RESULT, existsSubscriptModuleResultHandler);
			existsMyPostsToken.addEventListener(SqliteDatabaseEvent.ERROR, existsSubscriptModuleFaultHandler);
			existsMyPostsToken.start();
		}
		
		/**
		 * 检测我的文章模块返回 
		 * @param event 事件
		 * 
		 */		
		private function existsSubscriptModuleResultHandler(event:SqliteDatabaseEvent):void
		{
			var token:SqliteDatabaseToken = event.target as SqliteDatabaseToken;
			token.removeEventListener(SqliteDatabaseEvent.RESULT, existsSubscriptModuleResultHandler);
			token.removeEventListener(SqliteDatabaseEvent.ERROR, existsSubscriptModuleFaultHandler);
			
			if(event.recordset == null || event.recordset.length == 0)
			{
				//初始化系统设置模块
				var parameters:Dictionary = new Dictionary();
				parameters[":id"] = _subscriptModule.id;
				parameters[":title"] = _subscriptModule.title;
				parameters[":url"] = _subscriptModule.url;
				parameters[":createTime"] = new Date();
				
				_gnFacade.systemDatabase.execute("INSERT INTO sys_module(id,title,url,createTime,type,sortIndex,useCount) VALUES(:id, :title, :url, :createTime, 1, 2, 0)", parameters, true);
			}
			
			//更改Setting模块的排序
			var settingModule:Module = Module.getSettingModule();
			var params:Dictionary = new Dictionary();
			params[":id"] = settingModule.id;
			
			_gnFacade.systemDatabase.execute("UPDATE sys_module SET sortIndex=99 WHERE id=:id", params);
			
			var e:PatchEvent = new PatchEvent(PatchEvent.PATCH_SUCCESS);
			e.name = CreateSubscriptModulePatch.NAME;
			this.dispatchEvent(e);
			
		}
		
		/**
		 * 检测我的文章模块错误 
		 * @param event 事件
		 * 
		 */		
		private function existsSubscriptModuleFaultHandler(event:SqliteDatabaseEvent):void
		{
			var token:SqliteDatabaseToken = event.target as SqliteDatabaseToken;
			token.removeEventListener(SqliteDatabaseEvent.RESULT, existsSubscriptModuleResultHandler);
			token.removeEventListener(SqliteDatabaseEvent.ERROR, existsSubscriptModuleFaultHandler);
			
			var e:PatchEvent = new PatchEvent(PatchEvent.PATCH_FAIL);
			e.name = CreateSubscriptModulePatch.NAME;
			e.error = event.error;
			this.dispatchEvent(e);
		}
	}
}