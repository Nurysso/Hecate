export namespace main {
	
	export class CPUStats {
	    usage: number;
	    cores: number;
	    model: string;
	
	    static createFrom(source: any = {}) {
	        return new CPUStats(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.usage = source["usage"];
	        this.cores = source["cores"];
	        this.model = source["model"];
	    }
	}
	export class DiskStats {
	    device: string;
	    mountPoint: string;
	    used: number;
	    total: number;
	    percent: number;
	    fileSystem: string;
	
	    static createFrom(source: any = {}) {
	        return new DiskStats(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.device = source["device"];
	        this.mountPoint = source["mountPoint"];
	        this.used = source["used"];
	        this.total = source["total"];
	        this.percent = source["percent"];
	        this.fileSystem = source["fileSystem"];
	    }
	}
	export class NetworkStats {
	    down: string;
	    up: string;
	    activity: number;
	
	    static createFrom(source: any = {}) {
	        return new NetworkStats(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.down = source["down"];
	        this.up = source["up"];
	        this.activity = source["activity"];
	    }
	}
	export class TempStats {
	    cpu: number;
	    max: number;
	    unit: string;
	
	    static createFrom(source: any = {}) {
	        return new TempStats(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.cpu = source["cpu"];
	        this.max = source["max"];
	        this.unit = source["unit"];
	    }
	}
	export class GPUStats {
	    usage: number;
	    memory: number;
	    temp: number;
	    name: string;
	
	    static createFrom(source: any = {}) {
	        return new GPUStats(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.usage = source["usage"];
	        this.memory = source["memory"];
	        this.temp = source["temp"];
	        this.name = source["name"];
	    }
	}
	export class MemoryStats {
	    used: number;
	    total: number;
	    percent: number;
	    unit: string;
	
	    static createFrom(source: any = {}) {
	        return new MemoryStats(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.used = source["used"];
	        this.total = source["total"];
	        this.percent = source["percent"];
	        this.unit = source["unit"];
	    }
	}
	export class EnhancedSystemStats {
	    cpu: CPUStats;
	    ram: MemoryStats;
	    swap: MemoryStats;
	    gpu: GPUStats;
	    temp: TempStats;
	    disks: DiskStats[];
	    network: NetworkStats;
	    uptime: string;
	    processCount: number;
	
	    static createFrom(source: any = {}) {
	        return new EnhancedSystemStats(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.cpu = this.convertValues(source["cpu"], CPUStats);
	        this.ram = this.convertValues(source["ram"], MemoryStats);
	        this.swap = this.convertValues(source["swap"], MemoryStats);
	        this.gpu = this.convertValues(source["gpu"], GPUStats);
	        this.temp = this.convertValues(source["temp"], TempStats);
	        this.disks = this.convertValues(source["disks"], DiskStats);
	        this.network = this.convertValues(source["network"], NetworkStats);
	        this.uptime = source["uptime"];
	        this.processCount = source["processCount"];
	    }
	
		convertValues(a: any, classs: any, asMap: boolean = false): any {
		    if (!a) {
		        return a;
		    }
		    if (a.slice && a.map) {
		        return (a as any[]).map(elem => this.convertValues(elem, classs));
		    } else if ("object" === typeof a) {
		        if (asMap) {
		            for (const key of Object.keys(a)) {
		                a[key] = new classs(a[key]);
		            }
		            return a;
		        }
		        return new classs(a);
		    }
		    return a;
		}
	}
	
	export class GTKColors {
	    accentColor: string;
	    accentFgColor: string;
	    accentBgColor: string;
	    windowBgColor: string;
	    windowFgColor: string;
	    headerbarBgColor: string;
	    headerbarFgColor: string;
	    popoverBgColor: string;
	    popoverFgColor: string;
	    viewBgColor: string;
	    viewFgColor: string;
	    cardBgColor: string;
	    cardFgColor: string;
	    sidebarBgColor: string;
	    sidebarFgColor: string;
	
	    static createFrom(source: any = {}) {
	        return new GTKColors(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.accentColor = source["accentColor"];
	        this.accentFgColor = source["accentFgColor"];
	        this.accentBgColor = source["accentBgColor"];
	        this.windowBgColor = source["windowBgColor"];
	        this.windowFgColor = source["windowFgColor"];
	        this.headerbarBgColor = source["headerbarBgColor"];
	        this.headerbarFgColor = source["headerbarFgColor"];
	        this.popoverBgColor = source["popoverBgColor"];
	        this.popoverFgColor = source["popoverFgColor"];
	        this.viewBgColor = source["viewBgColor"];
	        this.viewFgColor = source["viewFgColor"];
	        this.cardBgColor = source["cardBgColor"];
	        this.cardFgColor = source["cardFgColor"];
	        this.sidebarBgColor = source["sidebarBgColor"];
	        this.sidebarFgColor = source["sidebarFgColor"];
	    }
	}
	
	

}

