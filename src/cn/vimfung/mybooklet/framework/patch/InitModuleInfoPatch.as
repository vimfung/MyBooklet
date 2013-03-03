package cn.vimfung.mybooklet.framework.patch
{
	import cn.vimfung.mybooklet.framework.GNFacade;
	import cn.vimfung.mybooklet.framework.db.SqliteDatabaseToken;
	import cn.vimfung.mybooklet.framework.events.PatchEvent;
	import cn.vimfung.mybooklet.framework.events.SqliteDatabaseEvent;
	import cn.vimfung.mybooklet.framework.model.Module;
	import cn.vimfung.gnotes.kit.ISystemManager;
	
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
	 * 初始化模块信息补丁 
	 * @author Administrator
	 * 
	 */	
	public class InitModuleInfoPatch extends EventDispatcher implements IPatchObject
	{
		/**
		 * 命令名称 
		 */		
		public static const NAME:String = "81DB5C3A450F0BDE";
		
		public function InitModuleInfoPatch()
		{
			super();
		}
		
		private var _myPostModule:Module;
		private var _settingModule:Module;
		private var _gnFacade:GNFacade;
		private var _tokenArray:Array = new Array();
		
		/**
		 * @inheritDoc
		 * 
		 * */
		public function start(system:ISystemManager):void
		{
			_gnFacade = GNFacade.getInstance();
			_myPostModule = Module.getMyPostsModule();
			_settingModule = Module.getSettingModule();
			
			//写入系统模块:我的文章
			var parameters:Dictionary = new Dictionary();
			parameters[":id"] = _myPostModule.id;
			var existsMyPostsToken:SqliteDatabaseToken = _gnFacade.systemDatabase.createCommandToken("SELECT id FROM sys_module WHERE id = :id", parameters);
			existsMyPostsToken.addEventListener(SqliteDatabaseEvent.RESULT, existsMyPostsModuleResultHandler);
			existsMyPostsToken.addEventListener(SqliteDatabaseEvent.ERROR, existsMyPostsModuleFaultHandler);
			_tokenArray.push(existsMyPostsToken);
			
			//写入系统模块：设置
			parameters = new Dictionary();
			parameters[":id"] = _settingModule.id;
			var existsSettingToken:SqliteDatabaseToken = _gnFacade.systemDatabase.createCommandToken("SELECT id FROM sys_module WHERE id = :id", parameters);
			existsSettingToken.addEventListener(SqliteDatabaseEvent.RESULT, existsSettingModuleResultHandler);
			existsSettingToken.addEventListener(SqliteDatabaseEvent.ERROR, existsSettingModuleFaultHandler);
			_tokenArray.push(existsSettingToken);
			
			existsMyPostsToken.start();
			existsSettingToken.start();
		}
		
		/**
		 * 检测我的文章模块返回 
		 * @param event 事件
		 * 
		 */		
		private function existsMyPostsModuleResultHandler(event:SqliteDatabaseEvent):void
		{
			var token:SqliteDatabaseToken = event.target as SqliteDatabaseToken;
			token.removeEventListener(SqliteDatabaseEvent.RESULT, existsMyPostsModuleResultHandler);
			token.removeEventListener(SqliteDatabaseEvent.ERROR, existsMyPostsModuleFaultHandler);
			
			if(event.recordset == null || event.recordset.length == 0)
			{
				//初始化系统设置模块
				var parameters:Dictionary = new Dictionary();
				parameters[":id"] = _myPostModule.id;
				parameters[":title"] = _myPostModule.title;
				parameters[":url"] = _myPostModule.url;
				parameters[":createTime"] = new Date();
				
				_gnFacade.systemDatabase.execute("INSERT INTO sys_module(id,title,url,createTime,type,sortIndex,useCount) VALUES(:id, :title, :url, :createTime, 1, 1, 0)", parameters, true);
			}
			
			this.finishCheck(token);
			
		}
		
		/**
		 * 检测我的文章模块错误 
		 * @param event 事件
		 * 
		 */		
		private function existsMyPostsModuleFaultHandler(event:SqliteDatabaseEvent):void
		{
			var token:SqliteDatabaseToken = event.target as SqliteDatabaseToken;
			token.removeEventListener(SqliteDatabaseEvent.RESULT, existsMyPostsModuleResultHandler);
			token.removeEventListener(SqliteDatabaseEvent.ERROR, existsMyPostsModuleFaultHandler);
			
			var e:PatchEvent = new PatchEvent(PatchEvent.PATCH_FAIL);
			e.name = InitModuleInfoPatch.NAME;
			e.error = event.error;
			this.dispatchEvent(e);
		}
		
		/**
		 * 检测系统设置模块返回 
		 * @param event 事件
		 * 
		 */		
		private function existsSettingModuleResultHandler(event:SqliteDatabaseEvent):void
		{
			var token:SqliteDatabaseToken = event.target as SqliteDatabaseToken;
			token.removeEventListener(SqliteDatabaseEvent.RESULT, existsSettingModuleFaultHandler);
			token.removeEventListener(SqliteDatabaseEvent.ERROR, existsSettingModuleFaultHandler);
			
			if(event.recordset == null || event.recordset.length == 0)
			{
				//初始化系统设置模块
				var parameters:Dictionary = new Dictionary();
				parameters[":id"] = _settingModule.id;
				parameters[":title"] = _settingModule.title;
				parameters[":url"] = _settingModule.url;
				parameters[":createTime"] = new Date();
				
				_gnFacade.systemDatabase.execute("INSERT INTO sys_module(id,title,url,createTime,type,sortIndex,useCount) VALUES(:id, :title, :url, :createTime, 1, 1, 0)", parameters, true);
			}
			
			this.finishCheck(token);
		}
		
		/**
		 * 检测系统设置模块错误 
		 * @param event 事件
		 * 
		 */		
		private function existsSettingModuleFaultHandler(event:SqliteDatabaseEvent):void
		{
			var token:SqliteDatabaseToken = event.target as SqliteDatabaseToken;
			token.removeEventListener(SqliteDatabaseEvent.RESULT, existsSettingModuleFaultHandler);
			token.removeEventListener(SqliteDatabaseEvent.ERROR, existsSettingModuleFaultHandler);
			
			var e:PatchEvent = new PatchEvent(PatchEvent.PATCH_FAIL);
			e.name = InitModuleInfoPatch.NAME;
			e.error = event.error;
			this.dispatchEvent(e);
		}
		
		/**
		 * 完成检测 
		 * @param token 令牌
		 * 
		 */		
		private function finishCheck(token:SqliteDatabaseToken):void
		{
			var index:int = _tokenArray.indexOf(token);
			if(index >= 0)
			{
				_tokenArray.splice(index,1);
				
				if(_tokenArray.length == 0)
				{
					var e:PatchEvent = new PatchEvent(PatchEvent.PATCH_SUCCESS);
					e.name = InitModuleInfoPatch.NAME;
					this.dispatchEvent(e);
				}
			}
		}
	}
}