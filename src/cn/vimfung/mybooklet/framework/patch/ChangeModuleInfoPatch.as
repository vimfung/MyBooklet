package cn.vimfung.mybooklet.framework.patch
{
	import cn.vimfung.gnotes.kit.ISystemManager;
	import cn.vimfung.mybooklet.framework.GNFacade;
	import cn.vimfung.mybooklet.framework.db.SqliteDatabaseToken;
	import cn.vimfung.mybooklet.framework.events.PatchEvent;
	import cn.vimfung.mybooklet.framework.model.Module;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.Dictionary;
	
	/**
	 * 补丁成功 
	 */	
	[Event(name="patchSuccess", type="cn.vimfung.mybooklet.framework.events.PatchEvent")]
	
	/**
	 * 补丁失败 
	 */	
	[Event(name="patchFail", type="cn.vimfung.mybooklet.framework.events.PatchEvent")]
	
	/**
	 * 变更模块信息补丁
	 * @author Administrator
	 * 
	 * @since	ver1.4.0
	 * 
	 */	
	public class ChangeModuleInfoPatch extends EventDispatcher implements IPatchObject
	{
		/**
		 * 命令名称 
		 */		
		public static const NAME:String = "0ED3E6203951378B";
		
		public function ChangeModuleInfoPatch(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		private var _myPostModule:Module;
		private var _settingModule:Module;
		private var _gnFacade:GNFacade;
		
		/**
		 * @inheritDoc
		 * 
		 */		
		public function start(system:ISystemManager):void
		{
			var e:PatchEvent = null;
			
			_gnFacade = GNFacade.getInstance();
			_myPostModule = Module.getMyPostsModule();
			_settingModule = Module.getSettingModule();
			
			try
			{
				//写入系统模块:我的文章
				var parameters:Dictionary = new Dictionary();
				parameters[":id"] = "cn.vimfung.gnotes.myposts";
				parameters[":url"] = _myPostModule.url;
				parameters[":newId"] = _myPostModule.id;
				var myPostToken:SqliteDatabaseToken = _gnFacade.systemDatabase.createCommandToken("UPDATE sys_module SET url=:url, id=:newId WHERE id=:id", parameters);
				myPostToken.startSync();
				
				//写入系统模块：设置
				parameters = new Dictionary();
				parameters[":id"] = "cn.vimfung.gnotes.setting";
				parameters[":url"] = _settingModule.url;
				parameters[":newId"] = _settingModule.id;
				var settingToken:SqliteDatabaseToken = _gnFacade.systemDatabase.createCommandToken("UPDATE sys_module SET url=:url, id=:newId WHERE id=:id", parameters);
				settingToken.startSync();
				
				//派发完成事件
				e = new PatchEvent(PatchEvent.PATCH_SUCCESS);
				e.name = ChangeModuleInfoPatch.NAME;
				this.dispatchEvent(e);
			}
			catch(err:Error)
			{
				e = new PatchEvent(PatchEvent.PATCH_FAIL);
				e.name = InitModuleInfoPatch.NAME;
				e.error = err;
				this.dispatchEvent(e);
			}
		}
	}
}